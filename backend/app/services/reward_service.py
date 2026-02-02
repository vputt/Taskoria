"""
Сервис начисления наград
"""
from typing import Tuple
from app.templates.reward_calculator import RewardCalculator, StandardRewardCalculator
from app.repositories.user_repository import UserRepository
from app.core.event_bus import EventBus, EventType


class RewardService:
    """
    Сервис начисления наград (с применением Template Method и Observer).
    
    Применяемые паттерны:
    - Template Method: калькулятор наград
    - Observer: публикация событий при повышении уровня
    - Dependency Injection: внедрение зависимостей
    """
    
    def __init__(
        self,
        calculator: RewardCalculator = None,
        user_repo: UserRepository = None,
        event_bus: EventBus = None
    ):
        """
        Инициализация сервиса.
        
        Args:
            calculator: Калькулятор наград (DI)
            user_repo: Репозиторий пользователей (DI)
            event_bus: Шина событий (DI)
        """
        self.calculator = calculator or StandardRewardCalculator()
        self.user_repo = user_repo
        self.event_bus = event_bus
    
    def calculate_rewards(
        self,
        task_description: str,
        priority: str,
        subtasks_count: int,
        category: str
    ) -> Tuple[int, int]:
        """
        Рассчитывает награды за задачу.
        
        Args:
            task_description: Описание задачи
            priority: Приоритет задачи
            subtasks_count: Количество подзадач
            category: Категория задачи
            
        Returns:
            Tuple[int, int]: (xp, coins)
        """
        return self.calculator.calculate(
            task_description,
            priority,
            subtasks_count,
            category
        )
    
    def apply_rewards(
        self,
        user_id: int,
        xp: int,
        coins: int
    ) -> dict:
        """
        Применяет награды к пользователю.
        
        Args:
            user_id: ID пользователя
            xp: Количество XP
            coins: Количество монет
            
        Returns:
            dict: Результат с информацией о повышении уровня
        """
        user = self.user_repo.get(user_id)
        if not user:
            raise ValueError("User not found")
        
        # Сохраняем старый уровень
        old_level = user.level
        
        # Добавляем награды
        leveled_up = user.add_xp(xp)
        user.add_coins(coins)
        
        # Сохраняем изменения
        self.user_repo.update(user, {})
        
        # Публикуем событие повышения уровня (Observer Pattern)
        if leveled_up and self.event_bus:
            self.event_bus.publish(EventType.LEVEL_UP, {
                "user_id": user_id,
                "old_level": old_level,
                "new_level": user.level
            })
        
        return {
            "xp_earned": xp,
            "coins_earned": coins,
            "level_up": leveled_up,
            "new_level": user.level if leveled_up else None,
            "total_xp": user.xp,
            "total_coins": user.coins
        }
    
    def calculate_and_apply_rewards(
        self,
        user_id: int,
        task_description: str,
        priority: str,
        subtasks_count: int,
        category: str
    ) -> dict:
        """
        Рассчитывает и применяет награды (Facade).
        
        Комбинирует два метода в один для удобства.
        
        Args:
            user_id: ID пользователя
            task_description: Описание задачи
            priority: Приоритет задачи
            subtasks_count: Количество подзадач
            category: Категория задачи
            
        Returns:
            dict: Результат с информацией о наградах
        """
        xp, coins = self.calculate_rewards(
            task_description,
            priority,
            subtasks_count,
            category
        )
        
        return self.apply_rewards(user_id, xp, coins)
