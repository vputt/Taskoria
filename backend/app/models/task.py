"""
Модель задачи
"""
from sqlalchemy import Column, Integer, String, Text, Enum, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
from app.database import Base
import enum


class TaskCategory(str, enum.Enum):
    """Категории задач"""
    STUDY = "учеба"
    WORK = "работа"
    HEALTH = "здоровье"
    PERSONAL = "личное"


class TaskPriority(str, enum.Enum):
    """Приоритеты задач"""
    LOW = "низкая"
    MEDIUM = "средняя"
    HIGH = "высокая"


class TaskStatus(str, enum.Enum):
    """Статусы задач"""
    ACTIVE = "активная"
    IN_PROGRESS = "в процессе"
    COMPLETED = "выполнена"
    CANCELLED = "отменена"


class TaskDifficulty(str, enum.Enum):
    """Сложность задач"""
    EASY = "легкая"
    MEDIUM = "средняя"
    HARD = "сложная"


class Task(Base):
    """
    Модель задачи (Aggregate Root в DDD).
    
    Задача является агрегатом, содержащим подзадачи.
    Все операции с подзадачами идут через задачу (обеспечение целостности).
    """
    __tablename__ = "tasks"
    
    # Основные поля
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    
    # Категоризация
    category = Column(Enum(TaskCategory), nullable=False)
    priority = Column(Enum(TaskPriority), nullable=False)
    difficulty = Column(Enum(TaskDifficulty), default=TaskDifficulty.MEDIUM)
    status = Column(Enum(TaskStatus), default=TaskStatus.ACTIVE, nullable=False)
    
    # Награды
    xp_reward = Column(Integer, default=10, nullable=False)
    coins_reward = Column(Integer, default=5, nullable=False)
    
    # Временные метки
    deadline = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Отношения (Aggregate - Task содержит Subtasks)
    user = relationship("User", back_populates="tasks")
    subtasks = relationship("Subtask", back_populates="task", cascade="all, delete-orphan", lazy="select")
    
    def complete(self) -> None:
        """
        Завершает задачу.
        
        Бизнес-логика на уровне агрегата (DDD).
        """
        self.status = TaskStatus.COMPLETED
        self.completed_at = func.now()
    
    def cancel(self) -> None:
        """Отменяет задачу"""
        self.status = TaskStatus.CANCELLED
    
    def start(self) -> None:
        """Начинает выполнение задачи"""
        if self.status == TaskStatus.ACTIVE:
            self.status = TaskStatus.IN_PROGRESS
    
    def __repr__(self) -> str:
        return f"<Task(id={self.id}, title={self.title}, status={self.status.value})>"
