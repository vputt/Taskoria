from dataclasses import dataclass
from typing import List

from app.models.shop import UserShopItem
from app.models.user import User
from app.repositories.shop_repository import UserShopItemRepository
from app.repositories.user_repository import UserRepository
from app.schemas.shop import ShopItemResponse


@dataclass(frozen=True)
class ShopCatalogItem:
    id: int
    name: str
    description: str
    price: int
    type: str
    asset_id: str

    @property
    def auto_place_on_purchase(self) -> bool:
        return self.type == "decoration"


class ShopService:
    _catalog: List[ShopCatalogItem] = [
        ShopCatalogItem(
            id=501,
            name="Боулинг",
            description="Развлекательный боулинг для верхнего квартала. После покупки сразу появляется на карте.",
            price=140,
            type="decoration",
            asset_id="bowling",
        ),
        ShopCatalogItem(
            id=502,
            name="Тир",
            description="Небольшой городской тир для активной зоны. Покупка сразу размещает его на закрепленном месте.",
            price=90,
            type="decoration",
            asset_id="shooting_range",
        ),
        ShopCatalogItem(
            id=503,
            name="Фургон с пончиками",
            description="Мобильная точка с перекусом для уютного квартала. После покупки сразу появляется на карте.",
            price=110,
            type="decoration",
            asset_id="donut_van",
        ),
        ShopCatalogItem(
            id=504,
            name="Кинотеатр",
            description="Большой кинотеатр для нижней части города. После покупки сразу занимает свое место на карте.",
            price=160,
            type="decoration",
            asset_id="cinema",
        ),
    ]

    def __init__(
        self,
        shop_repo: UserShopItemRepository,
        user_repo: UserRepository,
    ):
        self.shop_repo = shop_repo
        self.user_repo = user_repo

    def list_items(self, user_id: int) -> List[ShopItemResponse]:
        states = {
            item.item_id: item
            for item in self.shop_repo.get_user_items(user_id)
        }
        return [
            self._to_response(catalog_item, states.get(catalog_item.id))
            for catalog_item in self._catalog
        ]

    def purchase_item(self, user: User, item_id: int) -> ShopItemResponse:
        catalog_item = self._require_catalog_item(item_id)
        current_state = self.shop_repo.get_user_item(user.id, item_id)
        if current_state is not None and current_state.is_owned:
            return self._to_response(catalog_item, current_state)

        if not user.spend_coins(catalog_item.price):
            raise ValueError("Insufficient funds")

        self.user_repo.db.add(user)

        updated_state = self.shop_repo.create_or_update(
            user.id,
            item_id,
            is_owned=True,
            is_placed=catalog_item.auto_place_on_purchase,
            mark_purchased=True,
            commit=False,
        )
        self.shop_repo.db.commit()
        self.shop_repo.db.refresh(updated_state)
        return self._to_response(catalog_item, updated_state)

    def update_placement(
        self,
        user_id: int,
        item_id: int,
        *,
        is_placed: bool,
    ) -> ShopItemResponse:
        catalog_item = self._require_catalog_item(item_id)
        current_state = self.shop_repo.get_user_item(user_id, item_id)
        if current_state is None or not current_state.is_owned:
            raise ValueError("Item is not owned")

        updated_state = self.shop_repo.create_or_update(
            user_id,
            item_id,
            is_placed=is_placed,
        )
        return self._to_response(catalog_item, updated_state)

    def _require_catalog_item(self, item_id: int) -> ShopCatalogItem:
        for item in self._catalog:
            if item.id == item_id:
                return item
        raise ValueError("Shop item was not found")

    def _to_response(
        self,
        catalog_item: ShopCatalogItem,
        state: UserShopItem | None,
    ) -> ShopItemResponse:
        return ShopItemResponse(
            id=catalog_item.id,
            name=catalog_item.name,
            description=catalog_item.description,
            price=catalog_item.price,
            type=catalog_item.type,
            asset_id=catalog_item.asset_id,
            is_owned=False if state is None else state.is_owned,
            is_placed=False if state is None else state.is_placed,
        )
