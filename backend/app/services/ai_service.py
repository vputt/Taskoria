"""
Сервис работы с ИИ (Facade Pattern).

Паттерн: Facade
Обоснование: Упрощает работу с ИИ-стратегиями (разбиение задач, оценка сложности и наград), предоставляет единый интерфейс.
"""
from typing import List, Dict
from app.strategies.ai_strategy import AIStrategy, GigaChatStrategy
from app.config import settings


class AIService:
    """
    Фасад для работы с ИИ (Facade Pattern + Strategy Pattern).
    
    Применяемые паттерны:
    - Facade Pattern: упрощает взаимодействие с ИИ (разбиение задач, оценка сложности и наград)
    - Strategy Pattern: позволяет менять ИИ-провайдера (GigaChat и др.)
    - Dependency Injection: стратегия внедряется через конструктор
    """
    
    def __init__(self, strategy: AIStrategy = None):
        """
        Инициализация сервиса.
        
        Args:
            strategy: ИИ-стратегия (DI). Если None — используется GigaChat
        """
        self.strategy = strategy or GigaChatStrategy(settings.GIGACHAT_AUTHORIZATION_KEY)
    
    async def split_task(
        self,
        task_description: str,
        priority: str
    ) -> List[Dict[str, any]]:
        """
        Разбивает задачу на подзадачи через внешний сервис.
        
        Упрощённый интерфейс (Facade).
        
        Args:
            task_description: Описание задачи
            priority: Приоритет задачи
            
        Returns:
            Список подзадач
        """
        return await self.strategy.split_task(task_description, priority)
    
    async def estimate_difficulty(self, task_description: str) -> str:
        """
        Оценивает сложность задачи с помощью ИИ.
        
        Упрощённый интерфейс (Facade).
        
        Args:
            task_description: Описание задачи
            
        Returns:
            Сложность задачи
        """
        return await self.strategy.estimate_difficulty(task_description)
    
    async def estimate_rewards(
        self,
        task_description: str,
        difficulty: str,
        estimated_time_minutes: int,
        priority: str
    ) -> dict:
        """
        Оценивает награды за задачу через внешний сервис.
        
        Упрощённый интерфейс (Facade).
        
        Args:
            task_description: Описание задачи
            difficulty: Сложность задачи
            estimated_time_minutes: Примерное время выполнения в минутах
            priority: Приоритет задачи
            
        Returns:
            dict: {"xp": int, "coins": int} - награды за задачу
        """
        return await self.strategy.estimate_rewards(
            task_description,
            difficulty,
            estimated_time_minutes,
            priority
        )
    
    def set_strategy(self, strategy: AIStrategy) -> None:
        """
        Меняет ИИ-стратегию (Strategy Pattern).
        
        Args:
            strategy: Новая стратегия
        """
        self.strategy = strategy
