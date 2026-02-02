"""
Pydantic схемы для валидации и сериализации данных
"""
from app.schemas.user import UserCreate, UserResponse, UserUpdate
from app.schemas.task import TaskCreate, TaskResponse, TaskUpdate
from app.schemas.subtask import SubtaskCreate, SubtaskResponse
from app.schemas.achievement import AchievementResponse, UserAchievementResponse
from app.schemas.building import BuildingCreate, BuildingResponse
from app.schemas.statistics import StatisticsResponse

__all__ = [
    "UserCreate", "UserResponse", "UserUpdate",
    "TaskCreate", "TaskResponse", "TaskUpdate",
    "SubtaskCreate", "SubtaskResponse",
    "AchievementResponse", "UserAchievementResponse",
    "BuildingCreate", "BuildingResponse",
    "StatisticsResponse"
]
