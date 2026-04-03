"""
API endpoints для работы с пользователями
"""
from fastapi import APIRouter, Depends

from app.models.user import User
from app.models.task import TaskCategory
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
    completed_study = task_repo.count_completed_by_category(
        current_user.id,
        TaskCategory.STUDY,
    )
    completed_work = task_repo.count_completed_by_category(
        current_user.id,
        TaskCategory.WORK,
    )
    completed_health = task_repo.count_completed_by_category(
        current_user.id,
        TaskCategory.HEALTH,
    )
    completed_personal = task_repo.count_completed_by_category(
        current_user.id,
        TaskCategory.PERSONAL,
    )
    total_tasks = len(current_user.tasks)
    buildings_count = len(current_user.buildings)
    achievements_count = sum(
        (
            1 if total_tasks > 0 else 0,
            1 if tasks_completed >= 10 else 0,
            1 if current_user.streak >= 7 else 0,
            1 if buildings_count >= 4 else 0,
            1 if completed_study >= 10 else 0,
            1 if completed_work >= 7 else 0,
            1 if completed_health >= 4 else 0,
            1 if completed_personal >= 5 else 0,
        )
    )
    
    return UserProfile(
        **UserResponse.model_validate(current_user).model_dump(),
        tasks_completed=tasks_completed,
        achievements_count=achievements_count,
        buildings_count=buildings_count,
    )
