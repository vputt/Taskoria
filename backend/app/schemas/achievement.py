"""
Pydantic схемы для Achievement
"""
from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class AchievementBase(BaseModel):
    """Базовая схема достижения"""
    code: str
    name: str
    description: Optional[str] = None
    xp_reward: int = 0
    coins_reward: int = 0
    icon_name: Optional[str] = None


class AchievementResponse(AchievementBase):
    """Схема ответа с данными достижения"""
    id: int
    
    class Config:
        from_attributes = True


class UserAchievementResponse(BaseModel):
    """Схема достижения пользователя"""
    id: int
    achievement: AchievementResponse
    unlocked_at: datetime
    
    class Config:
        from_attributes = True


class AchievementUnlockResponse(BaseModel):
    """Ответ при разблокировке достижения"""
    achievement: AchievementResponse
    xp_earned: int
    coins_earned: int
