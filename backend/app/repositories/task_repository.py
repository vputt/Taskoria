"""
Репозиторий для работы с задачами
"""
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime
from app.repositories.base_repository import BaseRepository
from app.models.task import Task, TaskStatus, TaskCategory


class TaskRepository(BaseRepository[Task]):
    """
    Репозиторий для Task (Repository Pattern).
    
    Расширяет базовый репозиторий специфичными методами для задач.
    """
    
    def __init__(self, db: Session):
        super().__init__(Task, db)
    
    def get_by_user(
        self, 
        user_id: int, 
        skip: int = 0, 
        limit: int = 100
    ) -> List[Task]:
        """
        Получает задачи пользователя.
        
        Args:
            user_id: ID пользователя
            skip: Количество пропускаемых записей
            limit: Максимальное количество записей
            
        Returns:
            Список задач
        """
        return self.db.query(self.model).filter(
            self.model.user_id == user_id
        ).offset(skip).limit(limit).all()
    
    def get_by_status(
        self, 
        user_id: int, 
        status: TaskStatus
    ) -> List[Task]:
        """
        Получает задачи пользователя по статусу.
        
        Args:
            user_id: ID пользователя
            status: Статус задачи
            
        Returns:
            Список задач
        """
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.status == status
        ).all()
    
    def get_by_category(
        self, 
        user_id: int, 
        category: TaskCategory
    ) -> List[Task]:
        """
        Получает задачи пользователя по категории.
        
        Args:
            user_id: ID пользователя
            category: Категория задачи
            
        Returns:
            Список задач
        """
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.category == category
        ).all()
    
    def get_overdue(self, user_id: int) -> List[Task]:
        """
        Получает просроченные задачи пользователя.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Список просроченных задач
        """
        now = datetime.now()
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.status.in_([TaskStatus.ACTIVE, TaskStatus.IN_PROGRESS]),
            self.model.deadline < now
        ).all()
    
    def count_completed(self, user_id: int) -> int:
        """
        Подсчитывает количество выполненных задач пользователя.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Количество выполненных задач
        """
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.status == TaskStatus.COMPLETED
        ).count()
