"""
Модель подзадачи
"""
from sqlalchemy import Column, Integer, String, Text, Enum, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base
import enum


class SubtaskStatus(str, enum.Enum):
    """Статусы подзадач"""
    NOT_STARTED = "не начата"
    IN_PROGRESS = "в процессе"
    COMPLETED = "выполнена"


class Subtask(Base):
    """
    Модель подзадачи (часть агрегата Task в DDD).
    
    Подзадача является частью агрегата Task.
    Все операции с подзадачами должны идти через Task для обеспечения целостности.
    """
    __tablename__ = "subtasks"
    
    # Основные поля
    id = Column(Integer, primary_key=True, index=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    
    # Оценка времени
    estimated_time = Column(Integer, nullable=True)  # в минутах
    
    # Статус и порядок
    status = Column(Enum(SubtaskStatus), default=SubtaskStatus.NOT_STARTED, nullable=False)
    order_index = Column(Integer, nullable=False, default=0)
    
    # Отношения
    task = relationship("Task", back_populates="subtasks")
    
    def complete(self) -> None:
        """Завершает подзадачу"""
        self.status = SubtaskStatus.COMPLETED
    
    def start(self) -> None:
        """Начинает выполнение подзадачи"""
        if self.status == SubtaskStatus.NOT_STARTED:
            self.status = SubtaskStatus.IN_PROGRESS
    
    def __repr__(self) -> str:
        return f"<Subtask(id={self.id}, title={self.title}, status={self.status.value})>"
