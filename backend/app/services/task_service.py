"""
Task domain service.
"""
import logging
from datetime import date
from typing import List

from app.core.event_bus import EventBus, EventType
from app.models.subtask import Subtask
from app.models.task import Task, TaskDifficulty, TaskPriority, TaskStatus
from app.repositories.subtask_repository import SubtaskRepository
from app.repositories.task_repository import TaskRepository
from app.repositories.user_repository import UserRepository
from app.services.ai_service import AIService
from app.services.reward_service import RewardService
from app.states.streak_state import StreakManager

logger = logging.getLogger(__name__)


class TaskSplitConflictError(ValueError):
    """Raised when a task already has subtasks and replacement was not confirmed."""


class TaskService:
    """Application service for task flows."""

    DIFFICULTY_ALIASES = {
        TaskDifficulty.EASY.value.lower(): TaskDifficulty.EASY.value,
        "easy": TaskDifficulty.EASY.value,
        TaskDifficulty.MEDIUM.value.lower(): TaskDifficulty.MEDIUM.value,
        "medium": TaskDifficulty.MEDIUM.value,
        TaskDifficulty.HARD.value.lower(): TaskDifficulty.HARD.value,
        "hard": TaskDifficulty.HARD.value,
    }

    DIFFICULTY_ENUM_BY_VALUE = {
        TaskDifficulty.EASY.value: TaskDifficulty.EASY,
        TaskDifficulty.MEDIUM.value: TaskDifficulty.MEDIUM,
        TaskDifficulty.HARD.value: TaskDifficulty.HARD,
    }

    def __init__(
        self,
        task_repo: TaskRepository,
        subtask_repo: SubtaskRepository,
        user_repo: UserRepository,
        ai_service: AIService,
        reward_service: RewardService,
        event_bus: EventBus,
    ):
        self.task_repo = task_repo
        self.subtask_repo = subtask_repo
        self.user_repo = user_repo
        self.ai_service = ai_service
        self.reward_service = reward_service
        self.event_bus = event_bus
        self.streak_manager = StreakManager()

    async def create_task(self, user_id: int, task_data: dict) -> Task:
        """Creates a task and estimates rewards when they are absent."""
        task_data["user_id"] = user_id

        if "xp_reward" not in task_data or "coins_reward" not in task_data:
            try:
                task_description = task_data.get("description") or task_data.get("title", "")
                difficulty_text = await self._resolve_difficulty(task_data, task_description)
                estimated_time = task_data.get("estimated_time_minutes", 60)

                priority = task_data.get("priority", TaskPriority.MEDIUM.value)
                if hasattr(priority, "value"):
                    priority = priority.value

                rewards = await self.ai_service.estimate_rewards(
                    task_description=task_description,
                    difficulty=difficulty_text,
                    estimated_time_minutes=estimated_time,
                    priority=priority,
                )

                task_data["xp_reward"] = rewards["xp"]
                task_data["coins_reward"] = rewards["coins"]
            except Exception as exc:
                logger.warning("Failed to estimate rewards with AI: %s, using defaults", exc)
                task_data.setdefault("xp_reward", 15)
                task_data.setdefault("coins_reward", 8)

        task = self.task_repo.create(task_data)
        self.event_bus.publish(EventType.TASK_CREATED, {
            "user_id": user_id,
            "task_id": task.id,
            "category": task.category.value,
        })
        return task

    async def split_task_with_ai(
        self,
        task_id: int,
        replace_existing: bool = False,
    ) -> List[Subtask]:
        """Splits a task into subtasks with AI and optionally replaces old ones."""
        task = self.task_repo.get(task_id)
        if not task:
            raise ValueError("Task not found")

        if self.subtask_repo.has_for_task(task_id):
            if not replace_existing:
                raise TaskSplitConflictError(
                    "Task already has subtasks. Pass replace_existing=true to regenerate them."
                )
            self.subtask_repo.delete_by_task(task_id)

        subtasks_data = await self.ai_service.split_task(
            task.description or task.title,
            task.priority.value,
        )

        subtasks: List[Subtask] = []
        total_time = 0
        for subtask_data in subtasks_data:
            estimated_time = subtask_data.get("estimated_time", 30)
            total_time += estimated_time
            subtask = self.subtask_repo.create({
                "task_id": task_id,
                "title": subtask_data["title"],
                "description": subtask_data.get("description", ""),
                "estimated_time": estimated_time,
                "order_index": subtask_data.get("order_index", len(subtasks)),
            })
            subtasks.append(subtask)

        if subtasks and total_time > 0:
            try:
                rewards = await self.ai_service.estimate_rewards(
                    task_description=task.description or task.title,
                    difficulty=self._normalize_difficulty_value(task.difficulty.value),
                    estimated_time_minutes=total_time,
                    priority=task.priority.value,
                )
                task.xp_reward = rewards["xp"]
                task.coins_reward = rewards["coins"]
                self.task_repo.update(task, {})
            except Exception as exc:
                logger.warning("Failed to recalculate rewards after splitting: %s", exc)

        return subtasks

    def complete_task(self, task_id: int) -> dict:
        """Completes a task and applies reward and streak side effects."""
        task = self.task_repo.get(task_id)
        if not task:
            raise ValueError("Task not found")

        if task.status == TaskStatus.COMPLETED:
            raise ValueError("Task already completed")

        task.complete()
        self.task_repo.update(task, {})

        user = self.user_repo.get(task.user_id)
        old_streak = user.streak
        new_streak = self.streak_manager.update_streak(user, date.today())
        self.user_repo.update(user, {})

        if new_streak != old_streak:
            self.event_bus.publish(EventType.STREAK_UPDATED, {
                "user_id": user.id,
                "old_streak": old_streak,
                "new_streak": new_streak,
            })

        reward_result = self.reward_service.apply_rewards(
            user_id=task.user_id,
            xp=task.xp_reward,
            coins=task.coins_reward,
        )

        self.event_bus.publish(EventType.TASK_COMPLETED, {
            "user_id": task.user_id,
            "task_id": task.id,
            "task": task,
            "user": user,
            "xp_earned": reward_result["xp_earned"],
            "coins_earned": reward_result["coins_earned"],
        })

        return {
            "task": task,
            "streak": new_streak,
            **reward_result,
        }

    def get_user_tasks(self, user_id: int, skip: int = 0, limit: int = 100) -> List[Task]:
        """Returns tasks for the user."""
        return self.task_repo.get_by_user(user_id, skip, limit)

    def get_task(self, task_id: int) -> Task:
        """Returns a task by id or raises when it does not exist."""
        task = self.task_repo.get(task_id)
        if not task:
            raise ValueError("Task not found")
        return task

    def update_task(self, task_id: int, task_data: dict) -> Task:
        """Updates the task with provided data."""
        task = self.get_task(task_id)
        clear_deadline = bool(task_data.pop("clear_deadline", False))
        if clear_deadline:
            task.deadline = None
        return self.task_repo.update(task, task_data)

    def delete_task(self, task_id: int) -> bool:
        """Deletes a task and publishes the corresponding event."""
        result = self.task_repo.delete(task_id)
        if result:
            self.event_bus.publish(EventType.TASK_DELETED, {"task_id": task_id})
        return result

    async def _resolve_difficulty(self, task_data: dict, task_description: str) -> str:
        """Resolves the canonical difficulty string for AI reward estimation."""
        if "difficulty" in task_data and task_data["difficulty"]:
            difficulty_text = self._normalize_difficulty_value(task_data["difficulty"])
        else:
            difficulty_text = self._normalize_difficulty_value(
                await self.ai_service.estimate_difficulty(task_description)
            )
            task_data["difficulty"] = self.DIFFICULTY_ENUM_BY_VALUE[difficulty_text]

        return difficulty_text

    def _normalize_difficulty_value(self, difficulty: TaskDifficulty | str) -> str:
        """Normalizes enum/string difficulty values to the canonical enum string."""
        if isinstance(difficulty, TaskDifficulty):
            return difficulty.value

        normalized = self.DIFFICULTY_ALIASES.get(str(difficulty).strip().lower())
        if normalized is None:
            return TaskDifficulty.MEDIUM.value
        return normalized
