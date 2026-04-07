from datetime import datetime, timezone
from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.shop import UserShopItem
from app.repositories.base_repository import BaseRepository


class UserShopItemRepository(BaseRepository[UserShopItem]):
    def __init__(self, db: Session):
        super().__init__(UserShopItem, db)

    def get_user_items(self, user_id: int) -> List[UserShopItem]:
        return self.db.query(self.model).filter(self.model.user_id == user_id).all()

    def get_user_item(self, user_id: int, item_id: int) -> Optional[UserShopItem]:
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.item_id == item_id,
        ).first()

    def create_or_update(
        self,
        user_id: int,
        item_id: int,
        *,
        is_owned: Optional[bool] = None,
        is_placed: Optional[bool] = None,
        mark_purchased: bool = False,
        commit: bool = True,
    ) -> UserShopItem:
        item = self.get_user_item(user_id, item_id)
        if item is None:
            item = UserShopItem(
                user_id=user_id,
                item_id=item_id,
                is_owned=is_owned if is_owned is not None else False,
                is_placed=is_placed if is_placed is not None else False,
                purchased_at=datetime.now(timezone.utc) if mark_purchased else None,
            )
            self.db.add(item)
        else:
            if is_owned is not None:
                item.is_owned = is_owned
            if is_placed is not None:
                item.is_placed = is_placed
            if mark_purchased and item.purchased_at is None:
                item.purchased_at = datetime.now(timezone.utc)

        if commit:
            self.db.commit()
            self.db.refresh(item)
        return item
