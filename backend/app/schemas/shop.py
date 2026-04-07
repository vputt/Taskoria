from pydantic import BaseModel


class ShopItemResponse(BaseModel):
    id: int
    name: str
    description: str
    price: int
    type: str
    asset_id: str
    is_owned: bool = False
    is_placed: bool = False


class ShopPlacementUpdate(BaseModel):
    is_placed: bool
