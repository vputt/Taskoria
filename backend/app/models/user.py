"""
Модель пользователя
"""
from sqlalchemy import Column, Integer, String, Date, DateTime, func
from sqlalchemy.orm import relationship
from app.database import Base

# Константы для системы уровней
XP_PER_LEVEL = 100  # Количество XP необходимое для повышения уровня


class User(Base):
    """
    Модель пользователя.
    
    Применяется в контексте DDD как Domain Entity (доменная сущность).
    Содержит бизнес-логику, связанную с пользователем.
    """
    __tablename__ = "users"
    
    # Основные поля
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, nullable=False)
    password_hash = Column(String, nullable=False)
    
    # Игровая механика
    level = Column(Integer, default=1, nullable=False)
    xp = Column(Integer, default=0, nullable=False)
    coins = Column(Integer, default=0, nullable=False)
    streak = Column(Integer, default=0, nullable=False)
    last_activity_date = Column(Date, nullable=True)
    
    # Временные метки
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Отношения (lazy loading - связано с Proxy Pattern)
    tasks = relationship("Task", back_populates="user", lazy="select")
    achievements = relationship("UserAchievement", back_populates="user", lazy="select")
    buildings = relationship("Building", back_populates="user", lazy="select")
    statistics = relationship("Statistics", back_populates="user", lazy="select")
    
    def add_xp(self, amount: int) -> bool:
        """
        Добавляет XP и проверяет повышение уровня.
        
        Бизнес-логика в модели (DDD Domain Entity).
        
        Args:
            amount: Количество XP
            
        Returns:
            bool: True если произошло повышение уровня
        """
        self.xp += amount
        new_level = self.calculate_level()
        
        if new_level > self.level:
            self.level = new_level
            return True
        return False
    
    def calculate_level(self) -> int:
        """
        Вычисляет уровень на основе текущего XP.
        
        Формула: level = (xp // XP_PER_LEVEL) + 1
        Уровень 1: 0-99 XP
        Уровень 2: 100-199 XP
        Уровень 3: 200-299 XP
        и т.д.
        
        Returns:
            int: Текущий уровень
        """
        return (self.xp // XP_PER_LEVEL) + 1
    
    def get_xp_to_next_level(self) -> int:
        """
        Вычисляет сколько XP нужно до следующего уровня.
        
        Returns:
            int: Количество XP до следующего уровня
        """
        current_level_xp = (self.level - 1) * XP_PER_LEVEL
        next_level_xp = self.level * XP_PER_LEVEL
        return next_level_xp - self.xp
    
    def add_coins(self, amount: int) -> None:
        """Добавляет монеты"""
        self.coins += amount
    
    def spend_coins(self, amount: int) -> bool:
        """
        Тратит монеты.
        
        Returns:
            bool: True если хватило монет, False иначе
        """
        if self.coins >= amount:
            self.coins -= amount
            return True
        return False
    
    def __repr__(self) -> str:
        return f"<User(id={self.id}, email={self.email}, level={self.level})>"
