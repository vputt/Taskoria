from datetime import datetime
from pathlib import Path
import sys
from types import SimpleNamespace
from unittest.mock import AsyncMock, Mock

import pytest
from fastapi import HTTPException

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.api import auth, city, shop, subtasks, tasks, users
from app.models.subtask import Subtask, SubtaskStatus
from app.models.task import TaskCategory, TaskDifficulty, TaskPriority, TaskStatus
from app.models.user import User
from app.schemas.building import BuildingCreateRequest
from app.schemas.shop import ShopPlacementUpdate
from app.schemas.subtask import SubtaskCreate, SubtaskUpdate
from app.schemas.task import TaskCreate, TaskUpdate
from app.schemas.user import UserCreate
from app.services.task_service import TaskSplitConflictError


def make_user(user_id=1):
    return SimpleNamespace(
        id=user_id,
        email="user@example.com",
        username="user",
        password_hash="secret",
        level=1,
        xp=0,
        coins=0,
        streak=0,
        last_activity_date=None,
        created_at=datetime.now(),
        updated_at=datetime.now(),
        tasks=[],
        buildings=[],
    )


def make_task(user_id=1, status=TaskStatus.ACTIVE):
    now = datetime.now()
    return SimpleNamespace(
        id=10,
        user_id=user_id,
        title="Task",
        description="Description",
        category=TaskCategory.WORK,
        priority=TaskPriority.MEDIUM,
        difficulty=TaskDifficulty.MEDIUM,
        status=status,
        xp_reward=10,
        coins_reward=5,
        deadline=None,
        created_at=now,
        completed_at=None,
        updated_at=now,
        subtasks=[],
    )


def assert_http_error(exc_info, status_code):
    assert exc_info.value.status_code == status_code


def test_auth_routes_register_and_login_success_and_errors():
    auth_service = Mock()
    user = User(
        id=1,
        email="user@example.com",
        username="user",
        password_hash="secret",
        level=1,
        xp=0,
        coins=0,
        streak=0,
        last_activity_date=None,
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )
    auth_service.register_user.return_value = user
    auth_service.authenticate_user.return_value = user
    auth_service.create_access_token.return_value = "token"

    registered = auth.register(
        UserCreate(email="user@example.com", username="user", password="secret123"),
        auth_service=auth_service,
    )
    assert registered is user

    result = auth.login(
        form_data=SimpleNamespace(username="user@example.com", password="secret123"),
        auth_service=auth_service,
    )
    assert result["access_token"] == "token"
    assert result["token_type"] == "bearer"

    auth_service.register_user.side_effect = ValueError("duplicate")
    with pytest.raises(HTTPException) as exc:
        auth.register(
            UserCreate(email="user@example.com", username="user", password="secret123"),
            auth_service=auth_service,
        )
    assert_http_error(exc, 400)

    auth_service.authenticate_user.return_value = None
    with pytest.raises(HTTPException) as exc:
        auth.login(
            form_data=SimpleNamespace(username="bad@example.com", password="secret123"),
            auth_service=auth_service,
        )
    assert_http_error(exc, 401)


@pytest.mark.asyncio
async def test_tasks_routes_success_and_error_branches():
    current_user = make_user(1)
    other_task = make_task(user_id=2)
    owned_task = make_task(user_id=1)
    task_service = Mock()
    task_service.get_user_tasks.return_value = [owned_task]
    task_service.create_task = AsyncMock(return_value=owned_task)
    task_service.get_task.return_value = owned_task
    task_service.update_task.return_value = owned_task
    task_service.delete_task.return_value = True
    task_service.complete_task.return_value = {
        "task": owned_task,
        "xp_earned": 10,
        "coins_earned": 5,
        "level_up": False,
        "new_level": None,
    }
    task_service.split_task_with_ai = AsyncMock(return_value=[
        Subtask(id=1, task_id=10, title="A", status=SubtaskStatus.NOT_STARTED, order_index=0)
    ])

    assert tasks.get_tasks(current_user=current_user, task_service=task_service) == [owned_task]
    created = await tasks.create_task(
        TaskCreate(title="Task", category=TaskCategory.WORK, priority=TaskPriority.MEDIUM),
        current_user=current_user,
        task_service=task_service,
    )
    assert created is owned_task
    assert tasks.get_task(10, current_user=current_user, task_service=task_service) is owned_task
    assert tasks.update_task(
        10,
        TaskUpdate(title="New"),
        current_user=current_user,
        task_service=task_service,
    ) is owned_task
    assert tasks.delete_task(10, current_user=current_user, task_service=task_service) is None
    assert tasks.complete_task(10, current_user=current_user, task_service=task_service).xp_earned == 10
    assert len(await tasks.split_task(10, current_user=current_user, task_service=task_service)) == 1

    task_service.get_task.return_value = other_task
    with pytest.raises(HTTPException) as exc:
        tasks.get_task(10, current_user=current_user, task_service=task_service)
    assert_http_error(exc, 403)

    task_service.get_task.side_effect = ValueError("Task not found")
    with pytest.raises(HTTPException) as exc:
        tasks.get_task(404, current_user=current_user, task_service=task_service)
    assert_http_error(exc, 404)

    task_service.get_task.side_effect = None
    task_service.get_task.return_value = make_task(user_id=1, status=TaskStatus.COMPLETED)
    with pytest.raises(HTTPException) as exc:
        tasks.update_task(10, TaskUpdate(title="New"), current_user=current_user, task_service=task_service)
    assert_http_error(exc, 400)
    with pytest.raises(HTTPException) as exc:
        tasks.delete_task(10, current_user=current_user, task_service=task_service)
    assert_http_error(exc, 400)

    task_service.get_task.return_value = owned_task
    task_service.split_task_with_ai.side_effect = TaskSplitConflictError("conflict")
    with pytest.raises(HTTPException) as exc:
        await tasks.split_task(10, current_user=current_user, task_service=task_service)
    assert_http_error(exc, 409)


def test_city_and_shop_routes_map_service_errors_to_http_statuses():
    current_user = make_user(1)
    service = Mock()
    building = SimpleNamespace(id=1, level=2)
    service.get_city_state.return_value = {"user_id": 1}
    service.build_building.return_value = (building, 100, 50)
    service.upgrade_building.return_value = (building, 75, 25)

    assert city.get_city(current_user=current_user, city_service=service) == {"user_id": 1}
    assert city.build_building(
        BuildingCreateRequest(building_type="office", position_x=0, position_y=0),
        current_user=current_user,
        city_service=service,
    )["cost"] == 100
    assert city.upgrade_building(1, current_user=current_user, city_service=service)["new_level"] == 2

    service.build_building.side_effect = ValueError("Insufficient funds")
    with pytest.raises(HTTPException) as exc:
        city.build_building(
            BuildingCreateRequest(building_type="office", position_x=0, position_y=0),
            current_user=current_user,
            city_service=service,
        )
    assert_http_error(exc, 400)

    service.upgrade_building.side_effect = PermissionError("No")
    with pytest.raises(HTTPException) as exc:
        city.upgrade_building(1, current_user=current_user, city_service=service)
    assert_http_error(exc, 403)

    shop_service = Mock()
    shop_service.list_items.return_value = []
    shop_service.purchase_item.return_value = SimpleNamespace(id=501)
    shop_service.update_placement.return_value = SimpleNamespace(id=501)
    assert shop.get_shop_items(current_user=current_user, shop_service=shop_service) == []
    assert shop.purchase_shop_item(501, current_user=current_user, shop_service=shop_service).id == 501
    assert shop.update_shop_item_placement(
        501,
        ShopPlacementUpdate(is_placed=True),
        current_user=current_user,
        shop_service=shop_service,
    ).id == 501

    shop_service.purchase_item.side_effect = ValueError("Shop item was not found")
    with pytest.raises(HTTPException) as exc:
        shop.purchase_shop_item(999, current_user=current_user, shop_service=shop_service)
    assert_http_error(exc, 404)

    shop_service.update_placement.side_effect = ValueError("Item is not owned")
    with pytest.raises(HTTPException) as exc:
        shop.update_shop_item_placement(
            999,
            ShopPlacementUpdate(is_placed=True),
            current_user=current_user,
            shop_service=shop_service,
        )
    assert_http_error(exc, 400)


def test_users_profile_counts_achievements_from_task_repo():
    current_user = make_user(1)
    current_user.tasks = [object()]
    current_user.buildings = [object(), object(), object(), object()]
    current_user.streak = 7
    task_repo = Mock()
    task_repo.count_completed.return_value = 12
    task_repo.count_completed_by_category.side_effect = [10, 7, 4, 5]

    profile = users.get_current_user_profile(current_user=current_user, task_repo=task_repo)

    assert profile.tasks_completed == 12
    assert profile.achievements_count == 8
    assert profile.buildings_count == 4


def test_subtask_routes_success_and_guard_errors():
    current_user = make_user(1)
    task = make_task(user_id=1)
    subtask = Subtask(id=1, task_id=10, title="A", status=SubtaskStatus.NOT_STARTED, order_index=0)
    task_repo = Mock()
    task_repo.get.return_value = task
    subtask_repo = Mock()
    subtask_repo.get.return_value = subtask
    subtask_repo.get_by_task.return_value = [subtask]
    subtask_repo.create.side_effect = lambda payload: SimpleNamespace(**payload)
    subtask_repo.update.side_effect = lambda item, _payload: item

    assert subtasks.get_subtasks(10, current_user, task_repo, subtask_repo) == [subtask]
    created = subtasks.create_subtask(
        10,
        SubtaskCreate(title="New", description="D"),
        current_user,
        task_repo,
        subtask_repo,
    )
    assert created.order_index == 1
    assert subtasks.update_subtask(1, SubtaskUpdate(title="Updated"), current_user, task_repo, subtask_repo) is subtask
    assert subtasks.start_subtask(1, current_user, task_repo, subtask_repo) is subtask
    assert subtask.status == SubtaskStatus.IN_PROGRESS
    assert subtasks.complete_subtask(1, current_user, task_repo, subtask_repo) is subtask
    assert subtask.status == SubtaskStatus.COMPLETED

    subtask.status = SubtaskStatus.NOT_STARTED
    assert subtasks.delete_subtask(1, current_user, task_repo, subtask_repo) is None
    subtask_repo.delete.assert_called_once_with(1)

    task_repo.get.return_value = None
    with pytest.raises(HTTPException) as exc:
        subtasks.get_subtasks(404, current_user, task_repo, subtask_repo)
    assert_http_error(exc, 404)

    task_repo.get.return_value = make_task(user_id=2)
    with pytest.raises(HTTPException) as exc:
        subtasks.create_subtask(10, SubtaskCreate(title="New"), current_user, task_repo, subtask_repo)
    assert_http_error(exc, 403)

    subtask_repo.get.return_value = None
    with pytest.raises(HTTPException) as exc:
        subtasks.update_subtask(1, SubtaskUpdate(title="New"), current_user, task_repo, subtask_repo)
    assert_http_error(exc, 404)

    subtask_repo.get.return_value = subtask
    task_repo.get.return_value = make_task(user_id=1, status=TaskStatus.COMPLETED)
    with pytest.raises(HTTPException) as exc:
        subtasks.delete_subtask(1, current_user, task_repo, subtask_repo)
    assert_http_error(exc, 400)
