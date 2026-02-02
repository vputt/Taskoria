"""
Event Bus для реализации Observer Pattern.

Паттерн: Observer (Наблюдатель) + Singleton
Обоснование: Обеспечивает слабую связанность между компонентами,
позволяет легко добавлять новых наблюдателей без изменения существующего кода.
"""
from typing import List, Callable, Dict, Any
from enum import Enum
import logging

logger = logging.getLogger(__name__)


class EventType(Enum):
    """Типы событий в системе"""
    TASK_CREATED = "task_created"
    TASK_COMPLETED = "task_completed"
    TASK_DELETED = "task_deleted"
    LEVEL_UP = "level_up"
    STREAK_UPDATED = "streak_updated"
    BUILDING_BUILT = "building_built"
    BUILDING_UPGRADED = "building_upgraded"
    ACHIEVEMENT_UNLOCKED = "achievement_unlocked"


class EventBus:
    """
    Event Bus для Observer Pattern + Singleton.
    
    Применяемые паттерны:
    - Observer Pattern: управление подписками и уведомлениями
    - Singleton: единственный экземпляр шины событий
    
    Преимущества:
    - Слабая связанность компонентов
    - Легко добавлять новых наблюдателей
    - Централизованное управление событиями
    
    Example:
        # Подписка на событие
        event_bus.subscribe(EventType.TASK_COMPLETED, achievement_observer.on_task_completed)
        
        # Публикация события
        event_bus.publish(EventType.TASK_COMPLETED, {"user_id": 1, "task_id": 10})
    """
    
    _instance: 'EventBus' = None
    
    def __new__(cls) -> 'EventBus':
        """Singleton: обеспечивает единственный экземпляр шины событий"""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._subscribers: Dict[EventType, List[Callable]] = {}
        return cls._instance
    
    def subscribe(self, event_type: EventType, handler: Callable[[Dict[str, Any]], None]) -> None:
        """
        Подписывается на событие.
        
        Args:
            event_type: Тип события
            handler: Обработчик события (принимает dict с данными)
        """
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []
        
        if handler not in self._subscribers[event_type]:
            self._subscribers[event_type].append(handler)
            logger.debug(f"Subscribed {handler.__name__} to {event_type.value}")
    
    def unsubscribe(self, event_type: EventType, handler: Callable) -> None:
        """
        Отписывается от события.
        
        Args:
            event_type: Тип события
            handler: Обработчик события
        """
        if event_type in self._subscribers and handler in self._subscribers[event_type]:
            self._subscribers[event_type].remove(handler)
            logger.debug(f"Unsubscribed {handler.__name__} from {event_type.value}")
    
    def publish(self, event_type: EventType, data: Dict[str, Any]) -> None:
        """
        Публикует событие всем подписчикам.
        
        Args:
            event_type: Тип события
            data: Данные события
        """
        logger.info(f"Publishing event: {event_type.value}")
        
        if event_type in self._subscribers:
            for handler in self._subscribers[event_type]:
                try:
                    handler(data)
                except Exception as e:
                    logger.error(
                        f"Error in event handler {handler.__name__} "
                        f"for event {event_type.value}: {str(e)}"
                    )
    
    def clear_subscribers(self) -> None:
        """Очищает все подписки (используется в тестах)"""
        self._subscribers.clear()


# Singleton instance
event_bus = EventBus()
