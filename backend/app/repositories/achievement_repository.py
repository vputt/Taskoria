"""
Репозиторий для работы с достижениями
"""
from sqlalchemy.orm import Session
from typing import List, Optional
from app.repositories.base_repository import BaseRepository
from app.models.achievement import Achievement, UserAchievement


class AchievementRepository(BaseRepository[Achievement]):
    """Репозиторий для Achievement"""
    
    def __init__(self, db: Session):
        super().__init__(Achievement, db)
    
    def get_by_code(self, code: str) -> Optional[Achievement]:
        """Получает достижение по коду"""
        return self.db.query(self.model).filter(
            self.model.code == code
        ).first()


class UserAchievementRepository(BaseRepository[UserAchievement]):
    """Репозиторий для UserAchievement"""
    
    def __init__(self, db: Session):
        super().__init__(UserAchievement, db)
    
    def get_user_achievements(self, user_id: int) -> List[UserAchievement]:
        """Получает достижения пользователя"""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id
        ).all()
    
    def has_achievement(self, user_id: int, achievement_id: int) -> bool:
        """Проверяет наличие достижения у пользователя"""
        return self.db.query(self.model).filter(
            self.model.user_id == user_id,
            self.model.achievement_id == achievement_id
        ).count() > 0
