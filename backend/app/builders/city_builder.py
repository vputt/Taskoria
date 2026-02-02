"""
Builder Pattern для построения объекта города.

Паттерн: Builder
Обоснование: Упрощает создание сложного объекта города,
делает код более читаемым, позволяет создавать объекты пошагово.
"""
from typing import List, Dict
from app.models.building import Building


class CityBuilder:
    """
    Строитель города (Builder Pattern).
    
    Применяемый паттерн: Builder Pattern
    - Пошаговое построение сложного объекта
    - Fluent Interface для удобства использования
    - Скрывает детали создания от клиента
    
    Преимущества:
    - Читаемый код
    - Гибкость в создании объектов
    - Можно создавать разные представления одного объекта
    
    Example:
        city = (CityBuilder(user_id=1)
                .add_building(building1)
                .add_building(building2)
                .build())
    """
    
    def __init__(self, user_id: int):
        """
        Инициализация строителя города.
        
        Args:
            user_id: ID пользователя
        """
        self.user_id = user_id
        self.buildings: List[Building] = []
        self._total_level = 0
        self._category_counts: Dict[str, int] = {}
    
    def add_building(self, building: Building) -> 'CityBuilder':
        """
        Добавляет здание в город (Fluent Interface).
        
        Args:
            building: Здание для добавления
            
        Returns:
            self: Возвращает себя для цепочки вызовов
        """
        if building.user_id != self.user_id:
            raise ValueError("Building belongs to different user")
        
        self.buildings.append(building)
        self._total_level += building.level
        
        # Обновляем счетчики категорий
        category = building.category.value
        self._category_counts[category] = self._category_counts.get(category, 0) + 1
        
        return self
    
    def add_buildings(self, buildings: List[Building]) -> 'CityBuilder':
        """
        Добавляет несколько зданий (Fluent Interface).
        
        Args:
            buildings: Список зданий
            
        Returns:
            self: Возвращает себя для цепочки вызовов
        """
        for building in buildings:
            self.add_building(building)
        return self
    
    def build(self) -> Dict:
        """
        Строит объект города.
        
        Returns:
            Dict: Объект города с полной информацией
        """
        return {
            "user_id": self.user_id,
            "buildings": self.buildings,
            "total_buildings": len(self.buildings),
            "total_level": self._total_level,
            "category_breakdown": self._category_counts,
            "average_level": self._calculate_average_level()
        }
    
    def _calculate_average_level(self) -> float:
        """
        Рассчитывает средний уровень зданий.
        
        Returns:
            float: Средний уровень
        """
        if not self.buildings:
            return 0.0
        return self._total_level / len(self.buildings)
    
    def get_buildings_by_category(self, category: str) -> List[Building]:
        """
        Возвращает здания по категории.
        
        Args:
            category: Категория
            
        Returns:
            List[Building]: Список зданий категории
        """
        return [b for b in self.buildings if b.category.value == category]
    
    def reset(self) -> 'CityBuilder':
        """
        Сбрасывает строителя для повторного использования.
        
        Returns:
            self: Возвращает себя
        """
        self.buildings = []
        self._total_level = 0
        self._category_counts = {}
        return self
