"""
Repository for subtask persistence operations.
"""
from typing import List

from sqlalchemy.orm import Session

from app.models.subtask import Subtask, SubtaskStatus
from app.repositories.base_repository import BaseRepository


class SubtaskRepository(BaseRepository[Subtask]):
    """Repository for `Subtask` entities."""

    def __init__(self, db: Session):
        super().__init__(Subtask, db)

    def get_by_task(self, task_id: int) -> List[Subtask]:
        """Return all subtasks for a task ordered by their position."""
        return self.db.query(self.model).filter(
            self.model.task_id == task_id
        ).order_by(self.model.order_index).all()

    def has_for_task(self, task_id: int) -> bool:
        """Check whether the task already has at least one subtask."""
        return self.db.query(self.model).filter(
            self.model.task_id == task_id
        ).count() > 0

    def delete_by_task(self, task_id: int) -> int:
        """Delete every subtask for a task and return the deleted count."""
        subtasks = self.db.query(self.model).filter(
            self.model.task_id == task_id
        ).all()

        deleted_count = len(subtasks)
        for subtask in subtasks:
            self.db.delete(subtask)

        if deleted_count:
            self.db.commit()

        return deleted_count

    def count_by_status(self, task_id: int, status: SubtaskStatus) -> int:
        """Count subtasks for a task with the given status."""
        return self.db.query(self.model).filter(
            self.model.task_id == task_id,
            self.model.status == status
        ).count()
