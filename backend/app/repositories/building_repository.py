"""
Репозиторий для работы со зданиями
"""
from sqlalchemy.orm import Session
from typing import List
from app.repositories.base_repository import BaseRepository
from app.models.building import Building


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
