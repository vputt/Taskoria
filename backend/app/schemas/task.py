"""
Pydantic схемы для Task
"""
from __future__ import annotations
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List

from app.models.task import TaskCategory, TaskPriority, TaskStatus, TaskDifficulty


class TaskBase(BaseModel):
    """Базовая схема задачи"""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    category: TaskCategory
    priority: TaskPriority
    deadline: Optional[datetime] = None


class TaskCreate(TaskBase):
    """
    Схема создания задачи.
    
    Используется при создании новой задачи через API.
    
    Награды (xp_reward, coins_reward) назначаются автоматически с помощью ИИ
    на основе сложности, времени выполнения и приоритета задачи.
    """
    difficulty: Optional[TaskDifficulty] = None  # Если не указано, ИИ оценит автоматически


class TaskUpdate(BaseModel):
    """Схема обновления задачи"""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    category: Optional[TaskCategory] = None
    priority: Optional[TaskPriority] = None
    difficulty: Optional[TaskDifficulty] = None
    status: Optional[TaskStatus] = None
    deadline: Optional[datetime] = None
    clear_deadline: bool = False


class TaskResponse(TaskBase):
    """
    Схема ответа с данными задачи.
    
    Возвращается в API.
    """
    id: int
    user_id: int
    status: TaskStatus
    difficulty: TaskDifficulty
    xp_reward: int
    coins_reward: int
    created_at: datetime
    completed_at: Optional[datetime]
    updated_at: datetime
    
    class Config:
        from_attributes = True


class TaskWithSubtasks(TaskResponse):
    """Задача с подзадачами"""
    # Используем строковую аннотацию для избежания циклического импорта
    subtasks: List["SubtaskResponse"] = Field(default_factory=list)
    
    class Config:
        from_attributes = True


class TaskSplitRequest(BaseModel):
    """Запрос на разбиение задачи на подзадачи через ИИ"""
    task_id: int
    

class TaskCompleteResponse(BaseModel):
    """Ответ после завершения задачи"""
    task: TaskResponse
    xp_earned: int
    coins_earned: int
    level_up: bool
    new_level: Optional[int] = None


# Разрешаем строковые аннотации после импорта SubtaskResponse
from app.schemas.subtask import SubtaskResponse
TaskWithSubtasks.model_rebuild()
