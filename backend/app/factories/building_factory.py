"""
Factory Pattern для создания зданий.

Паттерн: Factory Method + Abstract Factory
Обоснование: Инкапсулирует логику создания объектов зданий,
позволяет расширять систему новыми типами зданий без изменения существующего кода.
"""
from abc import ABC, abstractmethod
from app.models.building import Building
from app.models.task import TaskCategory


class BuildingFactory(ABC):
    """
    Абстрактная фабрика зданий (Abstract Factory Pattern).
    
    Применяемый паттерн: Abstract Factory + Factory Method
    - Определяет интерфейс для создания зданий
    - Инкапсулирует правила создания
    - Позволяет легко добавлять новые типы зданий
    
    Преимущества:
    - Централизованная логика создания
    - Легко расширять новыми типами
    - Скрывает детали создания от клиента
    
    Example:
        factory = StandardBuildingFactory()
        building = factory.create_building("университет", user_id, 0, 0)
    """
    
    @abstractmethod
    def create_building(
        self,
        building_type: str,
        user_id: int,
        position_x: int,
        position_y: int
    ) -> Building:
        """
        Создает здание.
        
        Args:
            building_type: Тип здания
            user_id: ID пользователя
            position_x: Позиция X на карте
            position_y: Позиция Y на карте
            
        Returns:
            Building: Созданное здание
        """
        pass
    
    @abstractmethod
    def get_building_cost(self, building_type: str, level: int = 1) -> int:
        """
        Возвращает стоимость здания.
        
        Args:
            building_type: Тип здания
            level: Уровень здания
            
        Returns:
            int: Стоимость в монетах
        """
        pass
    
    @abstractmethod
    def get_available_buildings(self) -> list[str]:
        """
        Возвращает список доступных типов зданий.
        
        Returns:
            list[str]: Список типов зданий
        """
        pass


class StandardBuildingFactory(BuildingFactory):
    """
    Стандартная фабрика зданий.
    
    Реализует создание стандартных типов зданий для игры.
    """
    
    # Стоимость базовых зданий
    BUILDING_COSTS = {
        "университет": 100,
        "библиотека": 80,
        "парк": 60,
        "спортзал": 90,
        "офис": 120,
        "кафе": 70,
        "больница": 150,
        "музей": 110
    }
    
    # Маппинг типов зданий на категории
    BUILDING_CATEGORIES = {
        "университет": TaskCategory.STUDY,
        "библиотека": TaskCategory.STUDY,
        "спортзал": TaskCategory.HEALTH,
        "больница": TaskCategory.HEALTH,
        "парк": TaskCategory.PERSONAL,
        "кафе": TaskCategory.PERSONAL,
        "офис": TaskCategory.WORK,
        "музей": TaskCategory.PERSONAL
    }
    
    def create_building(
        self,
        building_type: str,
        user_id: int,
        position_x: int,
        position_y: int
    ) -> Building:
        """
        Создает стандартное здание (Factory Method).
        
        Args:
            building_type: Тип здания
            user_id: ID пользователя
            position_x: Позиция X
            position_y: Позиция Y
            
        Returns:
            Building: Созданное здание
            
        Raises:
            ValueError: Если тип здания неизвестен
        """
        if building_type not in self.BUILDING_COSTS:
            raise ValueError(f"Unknown building type: {building_type}")
        
        category = self._get_category(building_type)
        
        building = Building(
            user_id=user_id,
            building_type=building_type,
            category=category,
            level=1,
            position_x=position_x,
            position_y=position_y
        )
        
        return building
    
    def get_building_cost(self, building_type: str, level: int = 1) -> int:
        """
        Рассчитывает стоимость здания.
        
        Стоимость увеличивается с уровнем (базовая_стоимость * level * 1.5).
        
        Args:
            building_type: Тип здания
            level: Уровень здания
            
        Returns:
            int: Стоимость в монетах
            
        Raises:
            ValueError: Если тип здания неизвестен
        """
        if building_type not in self.BUILDING_COSTS:
            raise ValueError(f"Unknown building type: {building_type}")
        
        base_cost = self.BUILDING_COSTS[building_type]
        return int(base_cost * (level * 1.5))
    
    def get_available_buildings(self) -> list[str]:
        """
        Возвращает список доступных типов зданий.
        
        Returns:
            list[str]: Список типов зданий
        """
        return list(self.BUILDING_COSTS.keys())
    
    def _get_category(self, building_type: str) -> TaskCategory:
        """
        Определяет категорию здания.
        
        Args:
            building_type: Тип здания
            
        Returns:
            TaskCategory: Категория здания
        """
        return self.BUILDING_CATEGORIES.get(
            building_type,
            TaskCategory.PERSONAL
        )
    
    def get_building_info(self, building_type: str) -> dict:
        """
        Возвращает информацию о здании.
        
        Args:
            building_type: Тип здания
            
        Returns:
            dict: Информация о здании
        """
        if building_type not in self.BUILDING_COSTS:
            raise ValueError(f"Unknown building type: {building_type}")
        
        return {
            "type": building_type,
            "base_cost": self.BUILDING_COSTS[building_type],
            "category": self._get_category(building_type).value
        }
