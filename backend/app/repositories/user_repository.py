"""
Репозиторий для работы с пользователями
"""
from sqlalchemy.orm import Session
from typing import Optional
from app.repositories.base_repository import BaseRepository
from app.models.user import User


class UserRepository(BaseRepository[User]):
    """
    Репозиторий для User (Repository Pattern).
    
    Расширяет базовый репозиторий специфичными методами для пользователей.
    """
    
    def __init__(self, db: Session):
        super().__init__(User, db)
    
    def get_by_email(self, email: str) -> Optional[User]:
        """
        Получает пользователя по email.
        
        Args:
            email: Email пользователя
            
        Returns:
            User или None
        """
        return self.db.query(self.model).filter(
            self.model.email == email
        ).first()
    
    def get_by_username(self, username: str) -> Optional[User]:
        """
        Получает пользователя по username.
        
        Args:
            username: Username пользователя
            
        Returns:
            User или None
        """
        return self.db.query(self.model).filter(
            self.model.username == username
        ).first()
    
    def email_exists(self, email: str) -> bool:
        """
        Проверяет существование email.
        
        Args:
            email: Email для проверки
            
        Returns:
            True если email существует
        """
        return self.db.query(self.model).filter(
            self.model.email == email
        ).count() > 0
