"""
Repository for working with tasks.
"""
from datetime import datetime
from typing import List

from sqlalchemy.orm import Session

from app.models.task import Task, TaskCategory, TaskStatus
from app.repositories.base_repository import BaseRepository


class TaskRepository(BaseRepository[Task]):
    """Repository with task-specific query helpers."""

    def __init__(self, db: Session):
        super().__init__(Task, db)

    def get_by_user(
        self,
        user_id: int,
        skip: int = 0,
        limit: int = 100
    ) -> List[Task]:
        """Return tasks for a user."""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id
        ).offset(skip).limit(limit).all()

    def get_by_status(
        self,
        user_id: int,
        status: TaskStatus
    ) -> List[Task]:
        """Return tasks for a user filtered by status."""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.status == status
        ).all()

    def get_by_category(
        self,
        user_id: int,
        category: TaskCategory
    ) -> List[Task]:
        """Return tasks for a user filtered by category."""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.category == category
        ).all()

    def get_overdue(self, user_id: int) -> List[Task]:
        """Return overdue active tasks for a user."""
        now = datetime.now()
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.status.in_([TaskStatus.ACTIVE, TaskStatus.IN_PROGRESS]),
            self.model.deadline < now
        ).all()

    def count_completed(self, user_id: int) -> int:
        """Count completed tasks for a user."""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.status == TaskStatus.COMPLETED
        ).count()

    def count_completed_by_category(
        self,
        user_id: int,
        category: TaskCategory
    ) -> int:
        """Count completed tasks for a user within a specific category."""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.category == category,
            self.model.status == TaskStatus.COMPLETED
        ).count()
