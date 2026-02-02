"""
Pydantic схемы для Statistics
"""
from pydantic import BaseModel
from datetime import date
from typing import Dict, Optional


class StatisticsBase(BaseModel):
    """Базовая схема статистики"""
    date: date
    tasks_completed: int = 0
    tasks_created: int = 0
    category_breakdown: Optional[Dict[str, int]] = None


class StatisticsResponse(StatisticsBase):
    """Схема ответа с данными статистики"""
    id: int
    user_id: int
    
    class Config:
        from_attributes = True


class StatisticsSummary(BaseModel):
    """Сводная статистика пользователя"""
    total_tasks_completed: int
    total_tasks_created: int
    completion_rate: float  # процент выполнения
    streak: int
    category_breakdown: Dict[str, int]
    activity_chart: list[StatisticsResponse]


class ActivityChartPoint(BaseModel):
    """Точка на графике активности"""
    date: date
    tasks_completed: int
    tasks_created: int
