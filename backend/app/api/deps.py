"""
Dependencies for API endpoints.
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.core.city_progression_policy import CityProgressionPolicy
from app.core.event_bus import event_bus
from app.database import get_db
from app.factories.building_factory import StandardBuildingFactory
from app.models.user import User
from app.repositories.building_repository import BuildingRepository
from app.repositories.shop_repository import UserShopItemRepository
from app.repositories.subtask_repository import SubtaskRepository
from app.repositories.task_repository import TaskRepository
from app.repositories.user_repository import UserRepository
from app.services.ai_service import AIService
from app.services.auth_service import AuthService
from app.services.city_service import CityService
from app.services.reward_service import RewardService
from app.services.shop_service import ShopService
from app.services.task_service import TaskService

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")


def get_user_repo(db: Session = Depends(get_db)) -> UserRepository:
    return UserRepository(db)


def get_task_repo(db: Session = Depends(get_db)) -> TaskRepository:
    return TaskRepository(db)


def get_subtask_repo(db: Session = Depends(get_db)) -> SubtaskRepository:
    return SubtaskRepository(db)


def get_building_repo(db: Session = Depends(get_db)) -> BuildingRepository:
    return BuildingRepository(db)


def get_shop_repo(db: Session = Depends(get_db)) -> UserShopItemRepository:
    return UserShopItemRepository(db)


def get_auth_service(user_repo: UserRepository = Depends(get_user_repo)) -> AuthService:
    return AuthService(user_repo)


def get_ai_service() -> AIService:
    return AIService()


def get_reward_service(user_repo: UserRepository = Depends(get_user_repo)) -> RewardService:
    return RewardService(user_repo=user_repo, event_bus=event_bus)


def get_building_factory() -> StandardBuildingFactory:
    return StandardBuildingFactory()


def get_city_progression_policy() -> CityProgressionPolicy:
    return CityProgressionPolicy()


def get_task_service(
    task_repo: TaskRepository = Depends(get_task_repo),
    subtask_repo: SubtaskRepository = Depends(get_subtask_repo),
    user_repo: UserRepository = Depends(get_user_repo),
    ai_service: AIService = Depends(get_ai_service),
    reward_service: RewardService = Depends(get_reward_service),
) -> TaskService:
    return TaskService(
        task_repo=task_repo,
        subtask_repo=subtask_repo,
        user_repo=user_repo,
        ai_service=ai_service,
        reward_service=reward_service,
        event_bus=event_bus,
    )


def get_city_service(
    user_repo: UserRepository = Depends(get_user_repo),
    building_repo: BuildingRepository = Depends(get_building_repo),
    task_repo: TaskRepository = Depends(get_task_repo),
    building_factory: StandardBuildingFactory = Depends(get_building_factory),
    progression_policy: CityProgressionPolicy = Depends(get_city_progression_policy),
) -> CityService:
    return CityService(
        user_repo=user_repo,
        building_repo=building_repo,
        task_repo=task_repo,
        building_factory=building_factory,
        progression_policy=progression_policy,
    )


def get_shop_service(
    shop_repo: UserShopItemRepository = Depends(get_shop_repo),
    user_repo: UserRepository = Depends(get_user_repo),
) -> ShopService:
    return ShopService(shop_repo=shop_repo, user_repo=user_repo)


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    auth_service: AuthService = Depends(get_auth_service),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
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
