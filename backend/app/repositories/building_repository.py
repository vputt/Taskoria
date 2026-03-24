"""
Репозиторий для работы со зданиями
"""
from typing import List

from sqlalchemy.orm import Session

from app.models.building import Building
from app.models.task import TaskCategory
from app.repositories.base_repository import BaseRepository


class BuildingRepository(BaseRepository[Building]):
    """Репозиторий для Building"""

    def __init__(self, db: Session):
        super().__init__(Building, db)

    def get_user_buildings(self, user_id: int) -> List[Building]:
        """Получает здания пользователя"""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id
        ).all()

    def count_user_buildings(self, user_id: int) -> int:
        """Подсчитывает количество зданий пользователя"""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id
        ).count()

    def get_by_user_and_position(self, user_id: int, position_x: int, position_y: int) -> Building | None:
        """Получает здание по позиции на карте конкретного пользователя"""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.position_x == position_x,
            self.model.position_y == position_y,
        ).first()

    def get_by_user_and_category(self, user_id: int, category: TaskCategory) -> Building | None:
        """Returns the oldest building for a user within a category."""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.category == category,
        ).order_by(self.model.id.asc()).first()
