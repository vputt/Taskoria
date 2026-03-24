"""
API endpoints для работы с городом и зданиями
"""
from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_city_service, get_current_user
from app.models.user import User
from app.schemas.building import (
    BuildingCreateRequest,
    BuildingPurchaseResponse,
    BuildingUpgradeResponse,
    CityResponse,
)
from app.services.city_service import CityService

router = APIRouter()


@router.get("", response_model=CityResponse)
def get_city(
    current_user: User = Depends(get_current_user),
    city_service: CityService = Depends(get_city_service),
):
    """Возвращает состояние города текущего пользователя."""
    return city_service.get_city_state(current_user.id)


@router.post("/buildings", response_model=BuildingPurchaseResponse, status_code=status.HTTP_201_CREATED)
def build_building(
    payload: BuildingCreateRequest,
    current_user: User = Depends(get_current_user),
    city_service: CityService = Depends(get_city_service),
):
    """Покупает и строит здание (со списанием coins)."""
    try:
        building, cost, balance_after = city_service.build_building(
            user_id=current_user.id,
            building_type=payload.building_type,
            x=payload.position_x,
            y=payload.position_y,
        )
        return {
            "building": building,
            "cost": cost,
            "balance_after": balance_after,
        }
    except ValueError as exc:
        message = str(exc)
        if message == "Insufficient funds":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=message)
        if message == "Cell is already occupied" or message.startswith("Unknown building type"):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=message)
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=message)


@router.patch("/buildings/{building_id}/upgrade", response_model=BuildingUpgradeResponse)
def upgrade_building(
    building_id: int,
    current_user: User = Depends(get_current_user),
    city_service: CityService = Depends(get_city_service),
):
    """Улучшает здание (со списанием coins)."""
    try:
        building, cost, balance_after = city_service.upgrade_building(
            user_id=current_user.id,
            building_id=building_id,
        )
        return {
            "building": building,
            "cost": cost,
            "new_level": building.level,
            "balance_after": balance_after,
        }
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc))
    except ValueError as exc:
        message = str(exc)
        if message == "Insufficient funds":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=message)
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=message)
