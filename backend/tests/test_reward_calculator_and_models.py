from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.factories.building_factory import StandardBuildingFactory
from app.models.building import Building
from app.models.subtask import Subtask, SubtaskStatus
from app.models.task import Task, TaskCategory, TaskPriority, TaskStatus
from app.models.user import User
from app.templates.reward_calculator import (
    PremiumRewardCalculator,
    StandardRewardCalculator,
)


def test_standard_reward_calculator_applies_priority_subtasks_and_limits():
    calculator = StandardRewardCalculator()

    xp, coins = calculator.calculate(
        task_description="Build project",
        priority=TaskPriority.HIGH.value,
        subtasks_count=3,
        category=TaskCategory.WORK.value,
    )

    assert xp == 24
    assert coins == 7
    assert calculator.get_priority_multiplier("unknown") == 1.0
    assert calculator.get_category_bonus("any") == 1.0
    assert calculator.apply_additional_modifiers(10, 5, "text") == (10, 5)


def test_premium_reward_calculator_adds_category_and_modifier_bonus():
    calculator = PremiumRewardCalculator()

    xp, coins = calculator.calculate(
        task_description="Train",
        priority=TaskPriority.HIGH.value,
        subtasks_count=4,
        category=TaskCategory.HEALTH.value,
    )

    assert xp == 55
    assert coins == 16
    assert calculator.get_max_xp() == 1000
    assert calculator.get_max_coins() == 500


def test_reward_calculator_clamps_minimum_and_maximum_values():
    standard = StandardRewardCalculator()
    premium = PremiumRewardCalculator()

    low_xp, low_coins = standard.calculate("", "none", -10, "none")
    high_xp, high_coins = premium.calculate("huge", TaskPriority.HIGH.value, 1000, TaskCategory.HEALTH.value)

    assert (low_xp, low_coins) == (5, 5)
    assert (high_xp, high_coins) == (1000, 16)


def test_user_domain_methods_level_and_coins():
    user = User(
        id=1,
        email="user@example.com",
        username="user",
        password_hash="secret",
        level=1,
        xp=95,
        coins=10,
    )

    assert user.add_xp(10) is True
    assert user.level == 2
    assert user.calculate_level() == 2
    assert user.get_xp_to_next_level() == 95
    user.add_coins(5)
    assert user.coins == 15
    assert user.spend_coins(20) is False
    assert user.spend_coins(12) is True
    assert user.coins == 3
    assert "user@example.com" in repr(user)


def test_task_subtask_and_building_domain_methods():
    task = Task(
        id=1,
        user_id=1,
        title="Demo",
        category=TaskCategory.WORK,
        priority=TaskPriority.MEDIUM,
        status=TaskStatus.ACTIVE,
    )
    task.start()
    assert task.status == TaskStatus.IN_PROGRESS
    task.complete()
    assert task.status == TaskStatus.COMPLETED
    task.cancel()
    assert task.status == TaskStatus.CANCELLED
    assert "Demo" in repr(task)

    subtask = Subtask(id=1, task_id=1, title="Part", status=SubtaskStatus.NOT_STARTED)
    subtask.start()
    assert subtask.status == SubtaskStatus.IN_PROGRESS
    subtask.complete()
    assert subtask.status == SubtaskStatus.COMPLETED
    assert "Part" in repr(subtask)

    building = Building(
        id=1,
        user_id=1,
        building_type="office",
        category=TaskCategory.WORK,
        level=2,
        position_x=0,
        position_y=0,
    )
    assert building.get_upgrade_cost() == 150
    building.upgrade()
    assert building.level == 3
    assert "office" in repr(building)


def test_standard_building_factory_creates_metadata_and_rejects_unknown_types():
    factory = StandardBuildingFactory()
    building_type = factory.get_progress_building_type(TaskCategory.WORK)
    building = factory.create_building(building_type, user_id=1, position_x=2, position_y=3)

    assert building.category == TaskCategory.WORK
    assert factory.get_building_cost(building_type, level=2) == 360
    assert building_type in factory.get_available_buildings()
    assert factory.get_building_info(building_type)["type"] == building_type

    try:
        factory.create_building("unknown", 1, 0, 0)
    except ValueError as exc:
        assert "Unknown building type" in str(exc)
    else:
        raise AssertionError("Unknown building type should fail")

    try:
        factory.get_building_info("unknown")
    except ValueError as exc:
        assert "Unknown building type" in str(exc)
    else:
        raise AssertionError("Unknown building info should fail")
