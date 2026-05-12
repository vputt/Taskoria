from datetime import date, datetime, timezone
from pathlib import Path
import sys
from unittest.mock import Mock

import pytest
from fastapi import HTTPException
from jose import jwt

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.api import deps
from app.config import settings
from app.builders.city_builder import CityBuilder
from app.core.city_progression_policy import CityProgressionPolicy
from app.core.container import DIContainer
from app.factories.building_factory import StandardBuildingFactory
from app.models.achievement import Achievement, UserAchievement
from app.models.building import Building
from app.models.shop import UserShopItem
from app.models.statistics import Statistics
from app.models.subtask import SubtaskStatus
from app.models.task import TaskCategory, TaskStatus
from app.models.user import User
from app.repositories.achievement_repository import AchievementRepository, UserAchievementRepository
from app.repositories.building_repository import BuildingRepository
from app.repositories.shop_repository import UserShopItemRepository
from app.repositories.statistics_repository import StatisticsRepository
from app.repositories.subtask_repository import SubtaskRepository
from app.repositories.task_repository import TaskRepository
from app.repositories.user_repository import UserRepository
from app.services.ai_service import AIService
from app.services.auth_service import AuthService
from app.services.city_service import CityService
from app.services.reward_service import RewardService
from app.services.shop_service import ShopService
from app.services.task_service import TaskService


def make_building(user_id=1, category=TaskCategory.STUDY, level=1, x=0, y=0):
    return Building(
        id=x + y + level,
        user_id=user_id,
        building_type="library",
        category=category,
        level=level,
        position_x=x,
        position_y=y,
    )


class FakeQuery:
    def __init__(self, first_result=None, all_result=None, count_result=0):
        self.first_result = first_result
        self.all_result = all_result or []
        self.count_result = count_result
        self.offset_value = None
        self.limit_value = None
        self.ordered = False

    def filter(self, *args):
        return self

    def order_by(self, *args):
        self.ordered = True
        return self

    def offset(self, value):
        self.offset_value = value
        return self

    def limit(self, value):
        self.limit_value = value
        return self

    def first(self):
        return self.first_result

    def all(self):
        return self.all_result

    def count(self):
        return self.count_result


class FakeDB:
    def __init__(self, query):
        self.query_obj = query
        self.added = []
        self.deleted = []
        self.commits = 0
        self.refreshed = []

    def query(self, _model):
        return self.query_obj

    def add(self, obj):
        self.added.append(obj)

    def commit(self):
        self.commits += 1

    def refresh(self, obj):
        self.refreshed.append(obj)

    def delete(self, obj):
        self.deleted.append(obj)


def test_di_container_registers_factories_singletons_and_clears():
    container = DIContainer()
    container.clear()

    container.register("factory", lambda: object())
    first = container.get("factory")
    second = container.get("factory")
    assert first is not second

    container.register("singleton", lambda: object(), singleton=True)
    assert container.get("singleton") is container.get("singleton")

    instance = object()
    container.register_singleton("instance", instance)
    assert container.get("instance") is instance

    with pytest.raises(ValueError, match="not registered"):
        container.get("missing")

    container.clear()
    with pytest.raises(ValueError):
        container.get("factory")


def test_city_builder_builds_summary_filters_and_resets():
    study = make_building(user_id=7, category=TaskCategory.STUDY, level=2, x=1)
    health = make_building(user_id=7, category=TaskCategory.HEALTH, level=4, x=2)

    builder = CityBuilder(user_id=7).add_buildings([study, health])
    city = builder.build()

    assert city["user_id"] == 7
    assert city["buildings"] == [study, health]
    assert city["total_buildings"] == 2
    assert city["total_level"] == 6
    assert city["average_level"] == 3
    assert city["category_breakdown"] == {
        TaskCategory.STUDY.value: 1,
        TaskCategory.HEALTH.value: 1,
    }
    assert builder.get_buildings_by_category(TaskCategory.STUDY.value) == [study]

    with pytest.raises(ValueError, match="different user"):
        builder.add_building(make_building(user_id=8))

    assert builder.reset().build()["average_level"] == 0.0


def test_statistics_counters_breakdown_and_repr():
    stats = Statistics(
        user_id=3,
        date=date(2026, 5, 20),
        tasks_completed=0,
        tasks_created=0,
        category_breakdown=None,
    )

    stats.increment_completed()
    stats.increment_created()
    stats.update_category_breakdown("study")
    stats.update_category_breakdown("study", 2)
    stats.update_category_breakdown("work", 4)

    assert stats.tasks_completed == 1
    assert stats.tasks_created == 1
    assert stats.category_breakdown == {"study": 3, "work": 4}
    assert "Statistics(user_id=3" in repr(stats)


def test_achievement_models_repr():
    achievement = Achievement(
        id=1,
        code="first_task",
        name="First task",
        description="Complete first task",
        xp_reward=10,
        coins_reward=5,
        icon_name="star",
    )
    user_achievement = UserAchievement(
        user_id=2,
        achievement_id=1,
        unlocked_at=datetime(2026, 5, 20, tzinfo=timezone.utc),
    )

    assert "Achievement(id=1, code=first_task" in repr(achievement)
    assert "UserAchievement(user_id=2, achievement_id=1)" in repr(user_achievement)


def test_api_dependency_factories_create_expected_objects():
    db = Mock()
    user_repo = deps.get_user_repo(db)
    task_repo = deps.get_task_repo(db)
    subtask_repo = deps.get_subtask_repo(db)
    building_repo = deps.get_building_repo(db)
    shop_repo = deps.get_shop_repo(db)

    assert isinstance(user_repo, UserRepository)
    assert isinstance(task_repo, TaskRepository)
    assert isinstance(subtask_repo, SubtaskRepository)
    assert isinstance(building_repo, BuildingRepository)
    assert isinstance(shop_repo, UserShopItemRepository)

    auth_service = deps.get_auth_service(user_repo)
    ai_service = deps.get_ai_service()
    reward_service = deps.get_reward_service(user_repo)
    building_factory = deps.get_building_factory()
    progression_policy = deps.get_city_progression_policy()
    task_service = deps.get_task_service(
        task_repo=task_repo,
        subtask_repo=subtask_repo,
        user_repo=user_repo,
        ai_service=ai_service,
        reward_service=reward_service,
    )
    city_service = deps.get_city_service(
        user_repo=user_repo,
        building_repo=building_repo,
        task_repo=task_repo,
        building_factory=building_factory,
        progression_policy=progression_policy,
    )
    shop_service = deps.get_shop_service(shop_repo=shop_repo, user_repo=user_repo)

    assert isinstance(auth_service, AuthService)
    assert isinstance(ai_service, AIService)
    assert isinstance(reward_service, RewardService)
    assert isinstance(building_factory, StandardBuildingFactory)
    assert isinstance(progression_policy, CityProgressionPolicy)
    assert isinstance(task_service, TaskService)
    assert isinstance(city_service, CityService)
    assert isinstance(shop_service, ShopService)


@pytest.mark.asyncio
async def test_get_current_user_decodes_jwt_and_rejects_invalid_tokens():
    user = User(
        id=7,
        email="user@example.com",
        username="user",
        password_hash="secret",
        level=1,
        xp=0,
        coins=0,
        streak=0,
    )
    auth_service = Mock()
    auth_service.get_user_by_id.return_value = user
    token = jwt.encode({"sub": "7"}, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

    assert await deps.get_current_user(token=token, auth_service=auth_service) is user
    auth_service.get_user_by_id.assert_called_with(7)

    invalid_cases = [
        "broken-token",
        jwt.encode({}, settings.SECRET_KEY, algorithm=settings.ALGORITHM),
    ]
    for invalid_token in invalid_cases:
        with pytest.raises(HTTPException) as exc:
            await deps.get_current_user(token=invalid_token, auth_service=auth_service)
        assert exc.value.status_code == 401

    auth_service.get_user_by_id.return_value = None
    with pytest.raises(HTTPException) as exc:
        await deps.get_current_user(token=token, auth_service=auth_service)
    assert exc.value.status_code == 401


def test_task_subtask_building_and_achievement_repositories_query_helpers():
    query = FakeQuery(first_result="one", all_result=["many"], count_result=2)
    db = FakeDB(query)

    task_repo = TaskRepository(db)
    assert task_repo.get_by_user(1, skip=3, limit=4) == ["many"]
    assert query.offset_value == 3
    assert query.limit_value == 4
    assert task_repo.get_by_status(1, TaskStatus.ACTIVE) == ["many"]
    assert task_repo.get_by_category(1, TaskCategory.STUDY) == ["many"]
    assert task_repo.get_overdue(1) == ["many"]
    assert task_repo.count_completed(1) == 2
    assert task_repo.count_completed_by_category(1, TaskCategory.STUDY) == 2

    subtask_repo = SubtaskRepository(db)
    assert subtask_repo.get_by_task(10) == ["many"]
    assert query.ordered is True
    assert subtask_repo.has_for_task(10) is True
    assert subtask_repo.count_by_status(10, SubtaskStatus.COMPLETED) == 2

    query.all_result = [Mock(), Mock()]
    assert subtask_repo.delete_by_task(10) == 2
    assert len(db.deleted) == 2
    assert db.commits == 1

    query.all_result = []
    assert subtask_repo.delete_by_task(10) == 0
    assert db.commits == 1

    building_repo = BuildingRepository(db)
    assert building_repo.get_user_buildings(1) == []
    assert building_repo.count_user_buildings(1) == 2
    assert building_repo.get_by_user_and_position(1, 2, 3) == "one"
    assert building_repo.get_by_user_and_category(1, TaskCategory.HEALTH) == "one"

    achievement_repo = AchievementRepository(db)
    user_achievement_repo = UserAchievementRepository(db)
    assert achievement_repo.get_by_code("first_task") == "one"
    assert user_achievement_repo.get_user_achievements(1) == []
    assert user_achievement_repo.has_achievement(1, 2) is True

    user_repo = UserRepository(db)
    assert user_repo.get_by_email("user@example.com") == "one"
    assert user_repo.get_by_username("user") == "one"
    assert user_repo.email_exists("user@example.com") is True


def test_shop_repository_creates_and_updates_items():
    query = FakeQuery(first_result=None)
    db = FakeDB(query)
    repo = UserShopItemRepository(db)

    query.all_result = ["owned-item"]
    assert repo.get_user_items(1) == ["owned-item"]

    created = repo.create_or_update(
        user_id=1,
        item_id=2,
        is_owned=True,
        is_placed=False,
        mark_purchased=True,
    )
    assert isinstance(created, UserShopItem)
    assert created in db.added
    assert created.is_owned is True
    assert created.is_placed is False
    assert created.purchased_at is not None
    assert db.commits == 1
    assert db.refreshed == [created]

    existing = UserShopItem(
        user_id=1,
        item_id=2,
        is_owned=False,
        is_placed=False,
        purchased_at=None,
    )
    query.first_result = existing
    updated = repo.create_or_update(
        user_id=1,
        item_id=2,
        is_owned=True,
        is_placed=True,
        mark_purchased=True,
        commit=False,
    )
    assert updated is existing
    assert updated.is_owned is True
    assert updated.is_placed is True
    assert updated.purchased_at is not None
    assert db.commits == 1


def test_statistics_repository_gets_or_creates_records():
    today = date(2026, 5, 20)
    existing = Statistics(
        user_id=1,
        date=today,
        tasks_completed=2,
        tasks_created=3,
    )
    query = FakeQuery(first_result=existing, all_result=[existing])
    db = FakeDB(query)
    repo = StatisticsRepository(db)

    assert repo.get_by_user_and_date(1, today) is existing
    assert repo.get_user_statistics(1, today, today) == [existing]
    assert query.ordered is True
    assert repo.get_or_create_today(1, today) is existing

    query.first_result = None
    created = repo.get_or_create_today(2, today)
    assert isinstance(created, Statistics)
    assert created.user_id == 2
    assert created in db.added
