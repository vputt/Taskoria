"""
Репозиторий для работы с подзадачами
"""
from sqlalchemy.orm import Session
from typing import List
from app.repositories.base_repository import BaseRepository
from app.models.subtask import Subtask, SubtaskStatus


class SubtaskRepository(BaseRepository[Subtask]):
    """Репозиторий для Subtask (Repository Pattern)"""
    
    def __init__(self, db: Session):
        super().__init__(Subtask, db)
    
    def get_by_task(self, task_id: int) -> List[Subtask]:
        """Получает подзадачи задачи"""
        return self.db.query(self.model).filter(
            self.model.task_id == task_id
        ).order_by(self.model.order_index).all()
    
    def count_by_status(self, task_id: int, status: SubtaskStatus) -> int:
        """Подсчитывает подзадачи по статусу"""
        return self.db.query(self.model).filter(
            self.model.task_id == task_id,
            self.model.status == status
        ).count()
