from pathlib import Path
import sys
from types import SimpleNamespace
from unittest.mock import AsyncMock, Mock

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.services.task_service import TaskService, TaskSplitConflictError


def make_service(existing_subtasks: bool) -> tuple[TaskService, SimpleNamespace, Mock, Mock]:
    task = SimpleNamespace(
        id=1,
        title="Coursework",
        description="Build frontend and finish backend logic",
        priority=SimpleNamespace(value="high"),
        difficulty=SimpleNamespace(value="hard"),
        xp_reward=0,
        coins_reward=0,
    )

    task_repo = Mock()
    task_repo.get.return_value = task
    task_repo.update.side_effect = lambda db_task, _: db_task

    subtask_repo = Mock()
    subtask_repo.has_for_task.return_value = existing_subtasks
    subtask_repo.create.side_effect = lambda payload: SimpleNamespace(
        id=payload["order_index"] + 1,
        status="not_started",
        **payload,
    )

    ai_service = Mock()
    ai_service.split_task = AsyncMock(return_value=[
        {
            "title": "Build frontend",
            "description": "Create the UI",
            "estimated_time": 180,
            "order_index": 0,
        },
        {
            "title": "Finish backend logic",
            "description": "Implement the missing flows",
            "estimated_time": 120,
            "order_index": 1,
        },
    ])
    ai_service.estimate_rewards = AsyncMock(return_value={"xp": 300, "coins": 150})

    service = TaskService(
        task_repo=task_repo,
        subtask_repo=subtask_repo,
        user_repo=Mock(),
        ai_service=ai_service,
        reward_service=Mock(),
        event_bus=Mock(),
    )

    return service, task, task_repo, subtask_repo


@pytest.mark.asyncio
async def test_split_task_with_ai_raises_conflict_when_subtasks_already_exist():
    service, _, _, subtask_repo = make_service(existing_subtasks=True)

    with pytest.raises(TaskSplitConflictError):
        await service.split_task_with_ai(task_id=1)

    subtask_repo.delete_by_task.assert_not_called()


@pytest.mark.asyncio
async def test_split_task_with_ai_replaces_existing_subtasks_when_confirmed():
    service, task, task_repo, subtask_repo = make_service(existing_subtasks=True)

    subtasks = await service.split_task_with_ai(task_id=1, replace_existing=True)

    subtask_repo.delete_by_task.assert_called_once_with(1)
    assert [subtask.title for subtask in subtasks] == [
        "Build frontend",
        "Finish backend logic",
    ]
    assert task.xp_reward == 300
    assert task.coins_reward == 150
    task_repo.update.assert_called_once()
