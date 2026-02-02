"""
Модели достижений
"""
from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from app.database import Base


class Achievement(Base):
    """
    Модель достижения.
    
    Используется в Factory Pattern для создания достижений разных типов.
    """
    __tablename__ = "achievements"
    
    # Основные поля
    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    
    # Награды
    xp_reward = Column(Integer, default=0, nullable=False)
    coins_reward = Column(Integer, default=0, nullable=False)
    
    # Иконка
    icon_name = Column(String, nullable=True)
    
    # Отношения
    user_achievements = relationship("UserAchievement", back_populates="achievement")
    
    def __repr__(self) -> str:
        return f"<Achievement(id={self.id}, code={self.code}, name={self.name})>"


class UserAchievement(Base):
    """
    Модель связи пользователя и достижения.
    
    Многие-ко-многим отношение между User и Achievement.
    """
    __tablename__ = "user_achievements"
    
    # Основные поля
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    achievement_id = Column(Integer, ForeignKey("achievements.id"), nullable=False, index=True)
    
    # Временная метка разблокировки
    unlocked_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Отношения
    user = relationship("User", back_populates="achievements")
    achievement = relationship("Achievement", back_populates="user_achievements")
    
    def __repr__(self) -> str:
        return f"<UserAchievement(user_id={self.user_id}, achievement_id={self.achievement_id})>"
