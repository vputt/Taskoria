"""
Template Method Pattern для расчета наград.

Паттерн: Template Method
Обоснование: Определяет скелет алгоритма расчета наград, позволяя подклассам
переопределять отдельные шаги без изменения структуры алгоритма.
Устраняет дублирование кода.
"""
from abc import ABC, abstractmethod
from typing import Tuple


class RewardCalculator(ABC):
    """
    Шаблонный метод для расчета наград (Template Method Pattern).
    
    Применяемый паттерн: Template Method
    - Определяет скелет алгоритма в методе calculate()
    - Подклассы переопределяют отдельные шаги
    - Инвариантная часть алгоритма остается в базовом классе
    
    Преимущества:
    - Переиспользование кода
    - Гибкость в настройке отдельных шагов
    - Четкая структура алгоритма
    
    Example:
        calculator = StandardRewardCalculator()
        xp, coins = calculator.calculate(
            task_description="Изучить Python",
            priority="высокая",
            subtasks_count=5,
            category="учеба"
        )
    """
    
    def calculate(
        self,
        task_description: str,
        priority: str,
        subtasks_count: int,
        category: str
    ) -> Tuple[int, int]:
        """
        Шаблонный метод - определяет алгоритм расчета наград.
        
        Это метод высокого уровня, который определяет последовательность шагов.
        Конкретная реализация шагов делегируется подклассам.
        
        Args:
            task_description: Описание задачи
            priority: Приоритет задачи
            subtasks_count: Количество подзадач
            category: Категория задачи
            
        Returns:
            Tuple[int, int]: (xp, coins)
        """
        # Шаг 1: Получить базовые награды
        base_xp, base_coins = self.get_base_rewards()
        
        # Шаг 2: Применить множитель приоритета
        priority_multiplier = self.get_priority_multiplier(priority)
        
        # Шаг 3: Применить бонус категории
        category_bonus = self.get_category_bonus(category)
        
        # Шаг 4: Применить бонус за подзадачи
        subtask_bonus = self.get_subtask_bonus(subtasks_count)
        
        # Шаг 5: Рассчитать финальные награды
        xp = int(base_xp * priority_multiplier * category_bonus * subtask_bonus)
        coins = int(base_coins * priority_multiplier * category_bonus)
        
        # Шаг 6: Применить дополнительные модификаторы (hook method)
        xp, coins = self.apply_additional_modifiers(xp, coins, task_description)
        
        # Шаг 7: Ограничить минимальные и максимальные значения
        xp = max(self.get_min_xp(), min(xp, self.get_max_xp()))
        coins = max(self.get_min_coins(), min(coins, self.get_max_coins()))
        
        return xp, coins
    
    @abstractmethod
    def get_base_rewards(self) -> Tuple[int, int]:
        """
        Возвращает базовые награды (XP и монеты).
        
        Абстрактный метод - должен быть переопределен в подклассах.
        
        Returns:
            Tuple[int, int]: (base_xp, base_coins)
        """
        pass
    
    def get_priority_multiplier(self, priority: str) -> float:
        """
        Возвращает множитель приоритета.
        
        Конкретная реализация - может быть переопределена в подклассах.
        
        Args:
            priority: Приоритет задачи
            
        Returns:
            float: Множитель приоритета
        """
        multipliers = {
            "высокая": 1.5,
            "средняя": 1.0,
            "низкая": 0.7
        }
        return multipliers.get(priority, 1.0)
    
    def get_category_bonus(self, category: str) -> float:
        """
        Возвращает бонус категории.
        
        Конкретная реализация - может быть переопределена в подклассах.
        
        Args:
            category: Категория задачи
            
        Returns:
            float: Бонус категории
        """
        # Базовая реализация - без бонуса
        return 1.0
    
    def get_subtask_bonus(self, subtasks_count: int) -> float:
        """
        Возвращает бонус за количество подзадач.
        
        Конкретная реализация - может быть переопределена в подклассах.
        
        Args:
            subtasks_count: Количество подзадач
            
        Returns:
            float: Бонус за подзадачи
        """
        # Бонус 20% за каждую подзадачу
        return 1.0 + (subtasks_count * 0.2)
    
    def apply_additional_modifiers(
        self,
        xp: int,
        coins: int,
        task_description: str
    ) -> Tuple[int, int]:
        """
        Применяет дополнительные модификаторы (Hook Method).
        
        Hook Method - может быть переопределен в подклассах для добавления
        дополнительной логики, но имеет пустую реализацию по умолчанию.
        
        Args:
            xp: Текущее значение XP
            coins: Текущее значение монет
            task_description: Описание задачи
            
        Returns:
            Tuple[int, int]: (modified_xp, modified_coins)
        """
        # Базовая реализация - без модификаторов
        return xp, coins
    
    def get_min_xp(self) -> int:
        """Минимальное значение XP"""
        return 5
    
    def get_max_xp(self) -> int:
        """Максимальное значение XP"""
        return 500
    
    def get_min_coins(self) -> int:
        """Минимальное значение монет"""
        return 1
    
    def get_max_coins(self) -> int:
        """Максимальное значение монет"""
        return 200


class StandardRewardCalculator(RewardCalculator):
    """
    Стандартный калькулятор наград.
    
    Используется для обычных пользователей.
    """
    
    def get_base_rewards(self) -> Tuple[int, int]:
        """Базовые награды для стандартных пользователей"""
        return 10, 5


class PremiumRewardCalculator(RewardCalculator):
    """
    Премиум калькулятор наград.
    
    Используется для премиум пользователей с увеличенными наградами
    и бонусами за категории.
    """
    
    def get_base_rewards(self) -> Tuple[int, int]:
        """Увеличенные базовые награды для премиум пользователей"""
        return 15, 8
    
    def get_category_bonus(self, category: str) -> float:
        """
        Переопределенные бонусы категорий для премиум пользователей.
        
        Премиум пользователи получают бонусы за разные категории задач.
        """
        bonuses = {
            "учеба": 1.2,
            "работа": 1.15,
            "здоровье": 1.25,
            "личное": 1.1
        }
        return bonuses.get(category, 1.0)
    
    def apply_additional_modifiers(
        self,
        xp: int,
        coins: int,
        task_description: str
    ) -> Tuple[int, int]:
        """
        Дополнительный бонус для премиум пользователей.
        
        Hook Method - добавляет 10% бонус к наградам.
        """
        xp = int(xp * 1.1)
        coins = int(coins * 1.1)
        return xp, coins
    
    def get_max_xp(self) -> int:
        """Увеличенный максимум XP для премиум"""
        return 1000
    
    def get_max_coins(self) -> int:
        """Увеличенный максимум монет для премиум"""
        return 500
