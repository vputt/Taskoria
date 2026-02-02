"""
Dependencies для API endpoints
"""
from typing import Generator
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.repositories.task_repository import TaskRepository
from app.repositories.subtask_repository import SubtaskRepository
from app.services.auth_service import AuthService
from app.services.task_service import TaskService
from app.services.ai_service import AIService
from app.services.reward_service import RewardService
from app.core.event_bus import event_bus

# OAuth2 схема
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")


def get_user_repo(db: Session = Depends(get_db)) -> UserRepository:
    """
    Dependency для получения UserRepository.
    
    Dependency Injection через FastAPI Depends.
    """
    return UserRepository(db)


def get_task_repo(db: Session = Depends(get_db)) -> TaskRepository:
    """Dependency для получения TaskRepository"""
    return TaskRepository(db)


def get_subtask_repo(db: Session = Depends(get_db)) -> SubtaskRepository:
    """Dependency для получения SubtaskRepository"""
    return SubtaskRepository(db)


def get_auth_service(
    user_repo: UserRepository = Depends(get_user_repo)
) -> AuthService:
    """
    Dependency для получения AuthService.
    
    Применяется многоуровневая DI:
    - FastAPI внедряет user_repo
    - AuthService получает user_repo через конструктор
    """
    return AuthService(user_repo)


def get_ai_service() -> AIService:
    """Dependency для получения ИИ-сервиса (разбиение задач, оценка сложности и наград)"""
    return AIService()


def get_reward_service(
    user_repo: UserRepository = Depends(get_user_repo)
) -> RewardService:
    """Dependency для получения RewardService"""
    return RewardService(user_repo=user_repo, event_bus=event_bus)


def get_task_service(
    task_repo: TaskRepository = Depends(get_task_repo),
    subtask_repo: SubtaskRepository = Depends(get_subtask_repo),
    user_repo: UserRepository = Depends(get_user_repo),
    ai_service: AIService = Depends(get_ai_service),
    reward_service: RewardService = Depends(get_reward_service)
) -> TaskService:
    """Dependency для получения TaskService"""
    return TaskService(
        task_repo=task_repo,
        subtask_repo=subtask_repo,
        user_repo=user_repo,
        ai_service=ai_service,
        reward_service=reward_service,
        event_bus=event_bus
    )


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    auth_service: AuthService = Depends(get_auth_service)
) -> User:
    """
    Dependency для получения текущего пользователя из JWT токена.
    
    Args:
        token: JWT токен
        auth_service: Сервис аутентификации
        
    Returns:
        User: Текущий пользователь
        
    Raises:
        HTTPException: Если токен невалиден
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        user_id: int = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = auth_service.get_user_by_id(int(user_id))
    if user is None:
        raise credentials_exception
    
    return user
