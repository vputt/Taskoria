from pathlib import Path
import sys
from types import SimpleNamespace
from unittest.mock import Mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.models.task import TaskStatus
from app.services.task_service import TaskService


def test_complete_task_applies_rewards_stored_on_task():
    task = SimpleNamespace(
        id=7,
        user_id=3,
        title="Prepare presentation",
        description="Finalize slides and rehearsal",
        priority=SimpleNamespace(value="high"),
        category=SimpleNamespace(value="work"),
        status=TaskStatus.ACTIVE,
        xp_reward=75,
        coins_reward=35,
        complete=Mock(side_effect=lambda: setattr(task, "status", TaskStatus.COMPLETED)),
    )
    user = SimpleNamespace(id=3, streak=2)

    task_repo = Mock()
    task_repo.get.return_value = task
    task_repo.update.side_effect = lambda db_task, _: db_task

    subtask_repo = Mock()
    user_repo = Mock()
    user_repo.get.return_value = user
    user_repo.update.side_effect = lambda db_user, _: db_user

    reward_service = Mock()
    reward_service.apply_rewards.return_value = {
        "xp_earned": 75,
        "coins_earned": 35,
        "level_up": False,
        "new_level": None,
        "total_xp": 1175,
        "total_coins": 240,
    }

    event_bus = Mock()

    service = TaskService(
        task_repo=task_repo,
        subtask_repo=subtask_repo,
        user_repo=user_repo,
        ai_service=Mock(),
        reward_service=reward_service,
        event_bus=event_bus,
    )
    service.streak_manager = Mock()
    service.streak_manager.update_streak.return_value = 2

    result = service.complete_task(task.id)

    reward_service.apply_rewards.assert_called_once_with(
        user_id=3,
        xp=75,
        coins=35,
    )
    assert result["xp_earned"] == 75
    assert result["coins_earned"] == 35
    assert result["task"] is task


def test_complete_task_rejects_repeated_completion_without_rewards():
    task = SimpleNamespace(
        id=7,
        user_id=3,
        status=TaskStatus.COMPLETED,
        xp_reward=75,
        coins_reward=35,
    )

    task_repo = Mock()
    task_repo.get.return_value = task

    reward_service = Mock()
    event_bus = Mock()

    service = TaskService(
        task_repo=task_repo,
        subtask_repo=Mock(),
        user_repo=Mock(),
        ai_service=Mock(),
        reward_service=reward_service,
        event_bus=event_bus,
    )

    try:
        service.complete_task(task.id)
    except ValueError as exc:
        assert str(exc) == "Task already completed"
    else:
        raise AssertionError("Expected repeated completion to fail")

    reward_service.apply_rewards.assert_not_called()
    event_bus.publish.assert_not_called()
