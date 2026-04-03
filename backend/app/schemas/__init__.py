"""
Pydantic схемы для валидации и сериализации данных
"""
from app.schemas.achievement import AchievementResponse, UserAchievementResponse
from app.schemas.building import (
    BuildingCreate,
    BuildingCreateRequest,
    BuildingPurchaseResponse,
    BuildingResponse,
    BuildingUpgradeResponse,
    CityResponse,
)
from app.schemas.statistics import StatisticsResponse
from app.schemas.subtask import SubtaskCreate, SubtaskResponse
from app.schemas.task import TaskCreate, TaskResponse, TaskUpdate
from app.schemas.user import UserCreate, UserResponse, UserUpdate

__all__ = [
    "UserCreate", "UserResponse", "UserUpdate",
    "TaskCreate", "TaskResponse", "TaskUpdate",
    "SubtaskCreate", "SubtaskResponse",
    "AchievementResponse", "UserAchievementResponse",
    "BuildingCreate", "BuildingCreateRequest", "BuildingPurchaseResponse",
    "BuildingResponse", "BuildingUpgradeResponse", "CityResponse",
    "StatisticsResponse"
]
