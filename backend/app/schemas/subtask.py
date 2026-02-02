"""
Pydantic схемы для Subtask
"""
from pydantic import BaseModel, Field
from typing import Optional
from app.models.subtask import SubtaskStatus


class SubtaskBase(BaseModel):
    """Базовая схема подзадачи"""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    estimated_time: Optional[int] = Field(None, gt=0)  # в минутах
    order_index: int = Field(default=0, ge=0)


class SubtaskCreate(BaseModel):
    """Схема создания подзадачи"""
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = None
    estimated_time: Optional[int] = Field(None, gt=0)  # в минутах
    order_index: Optional[int] = Field(None, ge=0)  # Если не указан — вычисляется автоматически


class SubtaskUpdate(BaseModel):
    """Схема обновления подзадачи"""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = None
    estimated_time: Optional[int] = Field(None, gt=0)
    status: Optional[SubtaskStatus] = None
    order_index: Optional[int] = Field(None, ge=0)


class SubtaskResponse(SubtaskBase):
    """Схема ответа с данными подзадачи"""
    id: int
    task_id: int
    status: SubtaskStatus
    
    class Config:
        from_attributes = True
