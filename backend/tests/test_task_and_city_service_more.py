from pathlib import Path
import sys
from types import SimpleNamespace
from unittest.mock import AsyncMock, Mock

import pytest
from sqlalchemy.exc import IntegrityError

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.city_progression_policy import CityProgressionPolicy
from app.factories.building_factory import StandardBuildingFactory
from app.models.building import Building
from app.models.task import TaskCategory, TaskDifficulty, TaskPriority, TaskStatus
from app.services.city_service import CityService
from app.services.task_service import TaskService


class CityFakeDB:
    def __init__(self):
        self.added = []
        self.commits = 0
        self.rollbacks = 0
        self.refreshed = []
        self.fail_commit = None

    def add(self, obj):
        self.added.append(obj)

    def commit(self):
        if self.fail_commit:
            raise self.fail_commit
        self.commits += 1

    def rollback(self):
        self.rollbacks += 1

    def refresh(self, obj):
        self.refreshed.append(obj)


class CityBuildingRepo:
    def __init__(self, buildings=None):
        self.db = CityFakeDB()
        self.buildings = list(buildings or [])

    def get(self, building_id):
        for building in self.buildings:
            if building.id == building_id:
                return building
        return None

    def get_user_buildings(self, user_id):
        return [item for item in self.buildings if item.user_id == user_id]

    def get_by_user_and_position(self, user_id, x, y):
        for building in self.buildings:
            if building.user_id == user_id and building.position_x == x and building.position_y == y:
                return building
        return None

    def get_by_user_and_category(self, user_id, category):
        matches = [
            item for item in self.buildings
            if item.user_id == user_id and item.category == category
        ]
        return sorted(matches, key=lambda item: item.id or 0)[0] if matches else None


class CityTaskRepo:
    def count_completed_by_category(self, _user_id, _category):
        return 0


def make_city_service(user=None, buildings=None):
    user_repo = Mock()
    user_repo.get.return_value = user
    building_repo = CityBuildingRepo(buildings)
    service = CityService(
        user_repo=user_repo,
        building_repo=building_repo,
        task_repo=CityTaskRepo(),
        building_factory=StandardBuildingFactory(),
        progression_policy=CityProgressionPolicy(),
    )
    return service, building_repo


def make_task_service():
    return TaskService(
        task_repo=Mock(),
        subtask_repo=Mock(),
        user_repo=Mock(),
        ai_service=Mock(),
        reward_service=Mock(),
        event_bus=Mock(),
    )


@pytest.mark.asyncio
async def test_create_task_estimates_rewards_and_publishes_event():
    service = make_task_service()
    service.ai_service.estimate_difficulty = AsyncMock(return_value=TaskDifficulty.HARD.value)
    service.ai_service.estimate_rewards = AsyncMock(return_value={"xp": 80, "coins": 40})
    service.task_repo.create.side_effect = lambda payload: SimpleNamespace(id=9, **payload)

    task = await service.create_task(3, {
        "title": "Demo",
        "description": "Build demo",
        "priority": TaskPriority.HIGH,
        "category": TaskCategory.WORK,
    })

    assert task.user_id == 3
    assert task.xp_reward == 80
    assert task.coins_reward == 40
    assert task.difficulty == TaskDifficulty.HARD
    service.event_bus.publish.assert_called_once()


@pytest.mark.asyncio
async def test_create_task_uses_default_rewards_when_ai_fails():
    service = make_task_service()
    service.ai_service.estimate_difficulty = AsyncMock(side_effect=RuntimeError("offline"))
    service.task_repo.create.side_effect = lambda payload: SimpleNamespace(id=9, **payload)

    task = await service.create_task(3, {
        "title": "Demo",
        "priority": TaskPriority.MEDIUM.value,
        "category": TaskCategory.WORK,
    })

    assert task.xp_reward == 15
    assert task.coins_reward == 8


@pytest.mark.asyncio
async def test_split_task_with_ai_handles_missing_task_and_reward_recalculation_failure():
    service = make_task_service()
    service.task_repo.get.return_value = None
    with pytest.raises(ValueError, match="Task not found"):
        await service.split_task_with_ai(404)

    task = SimpleNamespace(
        id=1,
        title="Demo",
        description="Demo",
        priority=TaskPriority.MEDIUM,
        difficulty=TaskDifficulty.MEDIUM,
        xp_reward=0,
        coins_reward=0,
    )
    service.task_repo.get.return_value = task
    service.subtask_repo.has_for_task.return_value = False
    service.subtask_repo.create.side_effect = lambda payload: SimpleNamespace(**payload)
    service.ai_service.split_task = AsyncMock(return_value=[{"title": "A", "estimated_time": 10}])
    service.ai_service.estimate_rewards = AsyncMock(side_effect=RuntimeError("offline"))

    subtasks = await service.split_task_with_ai(1)

    assert len(subtasks) == 1
    assert task.xp_reward == 0
    service.task_repo.update.assert_not_called()


def test_task_service_get_update_delete_and_normalize_branches():
    service = make_task_service()
    task = SimpleNamespace(id=1, deadline="old")
    service.task_repo.get.return_value = task
    service.task_repo.update.side_effect = lambda db_task, data: SimpleNamespace(**vars(db_task), **data)
    service.task_repo.delete.return_value = True

    assert service.get_user_tasks(2, skip=1, limit=5) is service.task_repo.get_by_user.return_value
    service.task_repo.get_by_user.assert_called_once_with(2, 1, 5)
    assert service.get_task(1) is task

    updated = service.update_task(1, {"title": "New", "clear_deadline": True})
    assert task.deadline is None
    assert updated.title == "New"

    assert service.delete_task(1) is True
    service.event_bus.publish.assert_called_with(
        service.event_bus.publish.call_args.args[0],
        {"task_id": 1},
    )

    service.task_repo.get.return_value = None
    with pytest.raises(ValueError, match="Task not found"):
        service.get_task(404)

    assert service._normalize_difficulty_value(TaskDifficulty.HARD) == TaskDifficulty.HARD.value
    assert service._normalize_difficulty_value("easy") == TaskDifficulty.EASY.value
    assert service._normalize_difficulty_value("unknown") == TaskDifficulty.MEDIUM.value


def test_build_building_success_and_validation_errors():
    user = SimpleNamespace(id=1, coins=500)
    service, building_repo = make_city_service(user=user)
    building_type = service.building_factory.get_progress_building_type(TaskCategory.WORK)

    building, cost, remaining = service.build_building(1, building_type, 2, 2)

    assert building.position_x == 2
    assert cost == 180
    assert remaining == 320
    assert building_repo.db.commits == 1

    service, _ = make_city_service(user=None)
    with pytest.raises(ValueError, match="User not found"):
        service.build_building(1, building_type, 0, 0)

    occupied = Building(
        id=7,
        user_id=1,
        building_type=building_type,
        category=TaskCategory.WORK,
        level=1,
        position_x=0,
        position_y=0,
    )
    service, _ = make_city_service(user=SimpleNamespace(id=1, coins=500), buildings=[occupied])
    with pytest.raises(ValueError, match="Cell is already occupied"):
        service.build_building(1, building_type, 0, 0)

    service, _ = make_city_service(user=SimpleNamespace(id=1, coins=1))
    with pytest.raises(ValueError, match="Insufficient funds"):
        service.build_building(1, building_type, 0, 0)

    with pytest.raises(ValueError, match="Unknown building type"):
        service.build_building(1, "unknown", 0, 0)


def test_build_building_rolls_back_integrity_errors():
    user = SimpleNamespace(id=1, coins=500)
    service, building_repo = make_city_service(user=user)
    building_repo.db.fail_commit = IntegrityError("insert", {}, Exception("duplicate"))
    building_type = service.building_factory.get_progress_building_type(TaskCategory.WORK)

    with pytest.raises(ValueError, match="Cell is already occupied"):
        service.build_building(1, building_type, 2, 2)

    assert building_repo.db.rollbacks == 1


def test_upgrade_building_success_and_errors():
    building = Building(
        id=5,
        user_id=1,
        building_type="office",
        category=TaskCategory.WORK,
        level=1,
        position_x=0,
        position_y=0,
    )
    user = SimpleNamespace(id=1, coins=200)
    service, building_repo = make_city_service(user=user, buildings=[building])

    upgraded, cost, remaining = service.upgrade_building(1, 5)

    assert upgraded.level == 2
    assert cost == 75
    assert remaining == 125
    assert building_repo.db.commits == 1

    service, _ = make_city_service(user=None, buildings=[building])
    with pytest.raises(ValueError, match="User not found"):
        service.upgrade_building(1, 5)

    service, _ = make_city_service(user=SimpleNamespace(id=1, coins=200), buildings=[])
    with pytest.raises(ValueError, match="Building not found"):
        service.upgrade_building(1, 5)

    service, _ = make_city_service(user=SimpleNamespace(id=2, coins=200), buildings=[building])
    with pytest.raises(PermissionError, match="Not authorized"):
        service.upgrade_building(2, 5)

    service, _ = make_city_service(user=SimpleNamespace(id=1, coins=1), buildings=[building])
    with pytest.raises(ValueError, match="Insufficient funds"):
        service.upgrade_building(1, 5)


def test_city_progress_position_falls_back_when_anchor_is_occupied():
    anchor = Building(
        id=1,
        user_id=1,
        building_type="anchor",
        category=TaskCategory.PERSONAL,
        level=1,
        position_x=0,
        position_y=0,
    )
    service, _ = make_city_service(user=SimpleNamespace(id=1, coins=100), buildings=[anchor])

    assert service._resolve_progress_position(1, TaskCategory.STUDY) == (0, 1)
    assert service._find_next_free_position({(0, 0), (0, 1), (1, 0)}) == (1, 1)
