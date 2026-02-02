"""
API endpoints для работы с пользователями
"""
from fastapi import APIRouter, Depends

from app.models.user import User
from app.schemas.user import UserResponse, UserProfile
from app.api.deps import get_current_user, get_task_repo
from app.repositories.task_repository import TaskRepository

router = APIRouter()


@router.get("/me", response_model=UserProfile)
def get_current_user_profile(
    current_user: User = Depends(get_current_user),
    task_repo: TaskRepository = Depends(get_task_repo)
):
    """
    Получить профиль текущего пользователя.
    
    Args:
        current_user: Текущий пользователь (DI)
        task_repo: Репозиторий задач (DI)
        
    Returns:
        UserProfile: Профиль пользователя
    """
    # Подсчитываем статистику
    tasks_completed = task_repo.count_completed(current_user.id)
    
    return UserProfile(
        **UserResponse.model_validate(current_user).model_dump(),
        tasks_completed=tasks_completed,
        achievements_count=len(current_user.achievements),
        buildings_count=len(current_user.buildings)
    )
