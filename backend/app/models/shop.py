from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, UniqueConstraint, func
from sqlalchemy.orm import relationship

from app.database import Base


class UserShopItem(Base):
    __tablename__ = "user_shop_items"
    __table_args__ = (
        UniqueConstraint("user_id", "item_id", name="uq_user_shop_item"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    item_id = Column(Integer, nullable=False, index=True)
    is_owned = Column(Boolean, default=False, nullable=False)
    is_placed = Column(Boolean, default=False, nullable=False)
    purchased_at = Column(DateTime(timezone=True), nullable=True)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    user = relationship("User", back_populates="shop_items")
