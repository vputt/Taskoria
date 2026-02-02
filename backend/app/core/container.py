"""
Dependency Injection Container для управления зависимостями.

Паттерн: Dependency Injection + Singleton
Обоснование: Централизованное управление зависимостями упрощает 
тестирование, уменьшает связанность и следует принципу инверсии зависимостей (DIP).
"""
from typing import Dict, Callable, Any, TypeVar, Type
from functools import lru_cache

T = TypeVar('T')


class DIContainer:
    """
    Контейнер для управления зависимостями (DI Pattern + Singleton).
    
    Применяемые паттерны:
    - Dependency Injection: управление зависимостями
    - Singleton: единственный экземпляр контейнера
    - Factory: фабрики для создания сервисов
    
    Example:
        # Регистрация сервиса
        container.register("task_service", lambda: TaskService(task_repo))
        
        # Получение сервиса
        task_service = container.get("task_service")
    """
    
    _instance: 'DIContainer' = None
    
    def __new__(cls) -> 'DIContainer':
        """Singleton: обеспечивает единственный экземпляр контейнера"""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._services: Dict[str, Callable[[], Any]] = {}
            cls._instance._singletons: Dict[str, Any] = {}
        return cls._instance
    
    def register(
        self, 
        service_name: str, 
        factory: Callable[[], Any],
        singleton: bool = False
    ) -> None:
        """
        Регистрирует сервис в контейнере.
        
        Args:
            service_name: Имя сервиса (уникальный идентификатор)
            factory: Фабрика для создания экземпляра сервиса
            singleton: Если True, создается только один экземпляр
        """
        self._services[service_name] = factory
        if singleton:
            # Сохраняем информацию, что это singleton
            self._singletons[service_name] = None
    
    def get(self, service_name: str) -> Any:
        """
        Получает сервис из контейнера.
        
        Args:
            service_name: Имя сервиса
            
        Returns:
            Экземпляр сервиса
            
        Raises:
            ValueError: Если сервис не зарегистрирован
        """
        if service_name not in self._services:
            raise ValueError(f"Service '{service_name}' not registered in container")
        
        # Если это singleton и уже создан - возвращаем существующий
        if service_name in self._singletons:
            if self._singletons[service_name] is None:
                self._singletons[service_name] = self._services[service_name]()
            return self._singletons[service_name]
        
        # Иначе создаем новый экземпляр
        return self._services[service_name]()
    
    def register_singleton(self, service_name: str, instance: Any) -> None:
        """
        Регистрирует уже созданный экземпляр как singleton.
        
        Args:
            service_name: Имя сервиса
            instance: Экземпляр сервиса
        """
        self._services[service_name] = lambda: instance
        self._singletons[service_name] = instance
    
    def clear(self) -> None:
        """Очищает контейнер (используется в тестах)"""
        self._services.clear()
        self._singletons.clear()


# Singleton instance контейнера
container = DIContainer()
