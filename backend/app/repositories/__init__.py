"""
Репозитории для доступа к данным (Repository Pattern)
"""
from app.repositories.base_repository import BaseRepository
from app.repositories.user_repository import UserRepository
from app.repositories.task_repository import TaskRepository
from app.repositories.subtask_repository import SubtaskRepository
from app.repositories.achievement_repository import AchievementRepository
from app.repositories.building_repository import BuildingRepository
from app.repositories.statistics_repository import StatisticsRepository

__all__ = [
    "BaseRepository",
    "UserRepository",
    "TaskRepository",
    "SubtaskRepository",
    "AchievementRepository",
    "BuildingRepository",
    "StatisticsRepository"
]
