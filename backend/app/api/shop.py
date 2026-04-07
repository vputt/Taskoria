from typing import List

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user, get_shop_service
from app.models.user import User
from app.schemas.shop import ShopItemResponse, ShopPlacementUpdate
from app.services.shop_service import ShopService

router = APIRouter()


@router.get("", response_model=List[ShopItemResponse])
def get_shop_items(
    current_user: User = Depends(get_current_user),
    shop_service: ShopService = Depends(get_shop_service),
):
    return shop_service.list_items(current_user.id)


@router.post(
    "/items/{item_id}/purchase",
    response_model=ShopItemResponse,
    status_code=status.HTTP_201_CREATED,
)
def purchase_shop_item(
    item_id: int,
    current_user: User = Depends(get_current_user),
    shop_service: ShopService = Depends(get_shop_service),
):
    try:
        return shop_service.purchase_item(current_user, item_id)
    except ValueError as exc:
        detail = str(exc)
        if detail == "Insufficient funds":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)
        if detail == "Shop item was not found":
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=detail)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)


@router.patch("/items/{item_id}/placement", response_model=ShopItemResponse)
def update_shop_item_placement(
    item_id: int,
    payload: ShopPlacementUpdate,
    current_user: User = Depends(get_current_user),
    shop_service: ShopService = Depends(get_shop_service),
):
    try:
        return shop_service.update_placement(
            current_user.id,
            item_id,
            is_placed=payload.is_placed,
        )
    except ValueError as exc:
        detail = str(exc)
        if detail == "Shop item was not found":
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=detail)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)
