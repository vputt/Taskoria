"""
Pydantic схемы для User
"""
from pydantic import BaseModel, EmailStr, Field, model_validator
from datetime import date, datetime
from typing import Optional


class UserBase(BaseModel):
    """Базовая схема пользователя"""
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)


class UserCreate(UserBase):
    """
    Схема создания пользователя.
    
    Используется при регистрации.
    """
    password: str = Field(..., min_length=8, max_length=100)  # bcrypt_sha256 поддерживает пароли любой длины


class UserUpdate(BaseModel):
    """Схема обновления пользователя"""
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr] = None


class UserResponse(UserBase):
    """
    Схема ответа с данными пользователя.
    
    Возвращается в API (без пароля).
    """
    id: int
    level: int
    xp: int
    coins: int
    streak: int
    last_activity_date: Optional[date]
    created_at: datetime
    xp_to_next_level: int = 0  # Вычисляемое поле: сколько XP нужно до следующего уровня
    
    class Config:
        from_attributes = True  # Для совместимости с SQLAlchemy моделями
    
    @model_validator(mode='after')
    def calculate_xp_to_next_level(self):
        """
        Вычисляет xp_to_next_level после валидации.
        
        Если объект создан из модели User, используем её метод.
        Иначе вычисляем на основе полей level и xp.
        """
        # Если это валидация из SQLAlchemy модели, исходный объект доступен через __dict__
        # Но проще просто вычислить на основе полей
        from app.models.user import XP_PER_LEVEL
        
        current_level_xp = (self.level - 1) * XP_PER_LEVEL
        next_level_xp = self.level * XP_PER_LEVEL
        self.xp_to_next_level = max(0, next_level_xp - self.xp)
        
        return self


class UserProfile(UserResponse):
    """Расширенный профиль пользователя (с дополнительной информацией)"""
    tasks_completed: int = 0
    achievements_count: int = 0
    buildings_count: int = 0
    
    class Config:
        from_attributes = True
