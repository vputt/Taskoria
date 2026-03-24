"""
Модель здания
"""
from sqlalchemy import Column, DateTime, Enum, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import relationship

from app.database import Base
from app.models.task import TaskCategory


class Building(Base):
    """
    Модель здания в виртуальном городе.

    Создается через Factory Pattern (BuildingFactory).
    """

    __tablename__ = "buildings"
    __table_args__ = (
        UniqueConstraint("user_id", "position_x", "position_y", name="uq_buildings_user_position"),
    )

    # Основные поля
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    building_type = Column(String, nullable=False)  # университет, библиотека, парк и т.д.
    category = Column(Enum(TaskCategory), nullable=False)

    # Уровень здания
    level = Column(Integer, default=1, nullable=False)

    # Позиция на карте
    position_x = Column(Integer, nullable=False)
    position_y = Column(Integer, nullable=False)

    # Временные метки
    built_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    upgraded_at = Column(DateTime(timezone=True), nullable=True)

    # Отношения
    user = relationship("User", back_populates="buildings")

    def upgrade(self) -> None:
        """Повышает уровень здания."""
        self.level += 1
        self.upgraded_at = func.now()

    def get_upgrade_cost(self) -> int:
        """Рассчитывает стоимость улучшения."""
        base_cost = 50
        return int(base_cost * (self.level * 1.5))

    def __repr__(self) -> str:
        return f"<Building(id={self.id}, type={self.building_type}, level={self.level})>"
