"""
Репозиторий для работы со статистикой
"""
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date
from app.repositories.base_repository import BaseRepository
from app.models.statistics import Statistics


class StatisticsRepository(BaseRepository[Statistics]):
    """
    Репозиторий для Statistics.
    
    Используется в CQRS Pattern для оптимизированного чтения статистики.
    """
    
    def __init__(self, db: Session):
        super().__init__(Statistics, db)
    
    def get_by_user_and_date(
        self, 
        user_id: int, 
        date_value: date
    ) -> Optional[Statistics]:
        """Получает статистику по пользователю и дате"""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.date == date_value
        ).first()
    
    def get_user_statistics(
        self, 
        user_id: int, 
        start_date: date, 
        end_date: date
    ) -> List[Statistics]:
        """Получает статистику пользователя за период"""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.date >= start_date,
            self.model.date <= end_date
        ).order_by(self.model.date).all()
    
    def get_or_create_today(self, user_id: int, today: date) -> Statistics:
        """Получает или создает статистику за сегодня"""
        stats = self.get_by_user_and_date(user_id, today)
        if not stats:
            stats = self.create({
                "user_id": user_id,
                "date": today,
                "tasks_completed": 0,
                "tasks_created": 0
            })
        return stats
