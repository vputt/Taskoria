from pathlib import Path
import sys

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.models.shop import UserShopItem
from app.models.user import User
from app.services.shop_service import ShopService


class FakeDB:
    def __init__(self):
        self.commits = 0
        self.added = []

    def add(self, obj):
        self.added.append(obj)

    def commit(self):
        self.commits += 1

    def refresh(self, _obj):
        return None


class FakeUserRepository:
    def __init__(self):
        self.db = FakeDB()


class FakeShopRepository:
    def __init__(self):
        self.db = FakeDB()
        self.items = {}

    def get_user_items(self, user_id):
        return [
            item
            for item in self.items.values()
            if item.user_id == user_id
        ]

    def get_user_item(self, user_id, item_id):
        return self.items.get((user_id, item_id))

    def create_or_update(
        self,
        user_id,
        item_id,
        *,
        is_owned=None,
        is_placed=None,
        mark_purchased=False,
        commit=True,
    ):
        item = self.items.get((user_id, item_id))
        if item is None:
            item = UserShopItem(
                user_id=user_id,
                item_id=item_id,
                is_owned=False,
                is_placed=False,
            )
            self.items[(user_id, item_id)] = item

        if is_owned is not None:
            item.is_owned = is_owned
        if is_placed is not None:
            item.is_placed = is_placed
        if mark_purchased and item.purchased_at is None:
            item.purchased_at = object()

        if commit:
            self.db.commit()
            self.db.refresh(item)
        return item


def make_user(coins=200):
    return User(
        id=1,
        email="user@example.com",
        username="user",
        password_hash="test",
        coins=coins,
    )


def test_purchase_item_spends_coins_and_places_decoration():
    shop_repo = FakeShopRepository()
    user = make_user(coins=200)
    service = ShopService(shop_repo=shop_repo, user_repo=FakeUserRepository())

    item = service.purchase_item(user, 501)

    assert item.id == 501
    assert item.is_owned is True
    assert item.is_placed is True
    assert user.coins == 60
    assert shop_repo.db.commits == 1


def test_purchase_item_rejects_insufficient_coins_without_state_change():
    shop_repo = FakeShopRepository()
    user = make_user(coins=10)
    service = ShopService(shop_repo=shop_repo, user_repo=FakeUserRepository())

    with pytest.raises(ValueError, match="Insufficient funds"):
        service.purchase_item(user, 501)

    assert user.coins == 10
    assert shop_repo.items == {}
    assert shop_repo.db.commits == 0


def test_purchase_item_is_idempotent_for_owned_item():
    shop_repo = FakeShopRepository()
    user = make_user(coins=200)
    service = ShopService(shop_repo=shop_repo, user_repo=FakeUserRepository())

    first_purchase = service.purchase_item(user, 501)
    second_purchase = service.purchase_item(user, 501)

    assert first_purchase.is_owned is True
    assert second_purchase.is_owned is True
    assert user.coins == 60
    assert shop_repo.db.commits == 1


def test_update_placement_requires_owned_item():
    service = ShopService(
        shop_repo=FakeShopRepository(),
        user_repo=FakeUserRepository(),
    )

    with pytest.raises(ValueError, match="Item is not owned"):
        service.update_placement(1, 501, is_placed=True)
