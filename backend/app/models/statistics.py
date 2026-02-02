"""
Модель статистики
"""
from sqlalchemy import Column, Integer, Date, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.database import Base
from typing import Dict


class Statistics(Base):
    """
    Модель статистики пользователя.
    
    Используется в CQRS Pattern - оптимизированные модели для чтения.
    Агрегированные данные для быстрого доступа.
    """
    __tablename__ = "statistics"
    
    # Основные поля
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)
    
    # Статистика задач
    tasks_completed = Column(Integer, default=0, nullable=False)
    tasks_created = Column(Integer, default=0, nullable=False)
    
    # Распределение по категориям (JSONB для PostgreSQL)
    category_breakdown = Column(JSON, nullable=True, default=dict)
    
    # Отношения
    user = relationship("User", back_populates="statistics")
    
    def increment_completed(self) -> None:
        """Увеличивает счетчик выполненных задач"""
        self.tasks_completed += 1
    
    def increment_created(self) -> None:
        """Увеличивает счетчик созданных задач"""
        self.tasks_created += 1
    
    def update_category_breakdown(self, category: str, count: int = 1) -> None:
        """
        Обновляет распределение по категориям.
        
        Args:
            category: Категория задачи
            count: Количество (по умолчанию 1)
        """
        if self.category_breakdown is None:
            self.category_breakdown = {}
        
        if category in self.category_breakdown:
            self.category_breakdown[category] += count
        else:
            self.category_breakdown[category] = count
    
    def __repr__(self) -> str:
        return f"<Statistics(user_id={self.user_id}, date={self.date}, completed={self.tasks_completed})>"
