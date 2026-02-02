"""
State Pattern для управления streak (серией выполнения задач).

Паттерн: State
Обоснование: Инкапсулирует поведение, зависящее от состояния streak.
Упрощает добавление новых состояний и переходов. Делает код более читаемым.
"""
from abc import ABC, abstractmethod
from datetime import date
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.models.user import User


class StreakState(ABC):
    """
    Абстрактное состояние streak (State Pattern).
    
    Применяемый паттерн: State Pattern
    - Инкапсулирует поведение, зависящее от состояния
    - Упрощает добавление новых состояний
    - Делает переходы между состояниями явными
    
    Преимущества:
    - Четкое управление переходами
    - Легко добавлять новые состояния
    - Избегаем множественных if-else
    
    Example:
        state = ActiveStreakState()
        new_state = state.update(user, current_date)
    """
    
    @abstractmethod
    def update(self, user: 'User', current_date: date) -> 'StreakState':
        """
        Обновляет streak пользователя и возвращает новое состояние.
        
        Args:
            user: Пользователь
            current_date: Текущая дата
            
        Returns:
            Новое состояние streak
        """
        pass
    
    @abstractmethod
    def get_state_name(self) -> str:
        """
        Возвращает название состояния.
        
        Returns:
            Название состояния
        """
        pass


class NewStreakState(StreakState):
    """
    Состояние нового streak (первая активность пользователя).
    
    Переходы:
    - Всегда переходит в ActiveStreakState после первой активности
    """
    
    def update(self, user: 'User', current_date: date) -> 'StreakState':
        """
        Инициализирует новый streak.
        
        Args:
            user: Пользователь
            current_date: Текущая дата
            
        Returns:
            ActiveStreakState - активный streak
        """
        user.streak = 1
        user.last_activity_date = current_date
        return ActiveStreakState()
    
    def get_state_name(self) -> str:
        return "new"


class ActiveStreakState(StreakState):
    """
    Состояние активного streak (пользователь выполняет задачи последовательно).
    
    Переходы:
    - Если активность в следующий день → остаемся в ActiveStreakState (streak++)
    - Если активность в тот же день → остаемся в ActiveStreakState (streak не меняется)
    - Если пропущено больше 1 дня → переход в BrokenStreakState
    """
    
    def update(self, user: 'User', current_date: date) -> 'StreakState':
        """
        Обновляет активный streak.
        
        Args:
            user: Пользователь
            current_date: Текущая дата
            
        Returns:
            Новое состояние streak
        """
        if user.last_activity_date is None:
            # Если это первая активность
            user.streak = 1
            user.last_activity_date = current_date
            return self
        
        # Рассчитываем разницу в днях
        days_diff = (current_date - user.last_activity_date).days
        
        if days_diff == 0:
            # Активность в тот же день - streak не меняется
            return self
        elif days_diff == 1:
            # Активность на следующий день - увеличиваем streak
            user.streak += 1
            user.last_activity_date = current_date
            return self
        else:
            # Пропущено больше 1 дня - streak прерван
            user.streak = 1
            user.last_activity_date = current_date
            return BrokenStreakState()
    
    def get_state_name(self) -> str:
        return "active"


class BrokenStreakState(StreakState):
    """
    Состояние прерванного streak.
    
    Streak был прерван из-за пропуска дней.
    
    Переходы:
    - После любой активности → переход в ActiveStreakState (новый streak)
    """
    
    def update(self, user: 'User', current_date: date) -> 'StreakState':
        """
        Начинает новый streak после прерывания.
        
        Args:
            user: Пользователь
            current_date: Текущая дата
            
        Returns:
            ActiveStreakState - начинаем новый streak
        """
        user.streak = 1
        user.last_activity_date = current_date
        return ActiveStreakState()
    
    def get_state_name(self) -> str:
        return "broken"


class StreakManager:
    """
    Менеджер для управления streak с использованием State Pattern.
    
    Упрощает работу с состояниями streak.
    """
    
    def __init__(self):
        """Инициализация менеджера"""
        self._state: StreakState = NewStreakState()
    
    def update_streak(self, user: 'User', current_date: date = None) -> int:
        """
        Обновляет streak пользователя.
        
        Args:
            user: Пользователь
            current_date: Текущая дата (если None, используется сегодня)
            
        Returns:
            Текущее значение streak
        """
        if current_date is None:
            current_date = date.today()
        
        # Определяем текущее состояние
        if user.last_activity_date is None:
            self._state = NewStreakState()
        elif user.streak == 0:
            self._state = NewStreakState()
        else:
            # Проверяем, не прерван ли streak
            days_diff = (current_date - user.last_activity_date).days
            if days_diff > 1:
                self._state = BrokenStreakState()
            else:
                self._state = ActiveStreakState()
        
        # Обновляем через состояние
        self._state = self._state.update(user, current_date)
        
        return user.streak
    
    def get_current_state_name(self) -> str:
        """
        Возвращает название текущего состояния.
        
        Returns:
            Название состояния
        """
        return self._state.get_state_name()
