"""
Factory Pattern for building creation.
"""
from abc import ABC, abstractmethod

from app.models.building import Building
from app.models.task import TaskCategory


class BuildingFactory(ABC):
    """Abstract factory for building creation and metadata."""

    @abstractmethod
    def create_building(
        self,
        building_type: str,
        user_id: int,
        position_x: int,
        position_y: int,
    ) -> Building:
        """Creates a building entity."""

    @abstractmethod
    def get_building_cost(self, building_type: str, level: int = 1) -> int:
        """Returns building cost for the target level."""

    @abstractmethod
    def get_available_buildings(self) -> list[str]:
        """Returns available building types."""

    @abstractmethod
    def get_progress_building_type(self, category: TaskCategory) -> str:
        """Returns the canonical progression building for a category."""


class StandardBuildingFactory(BuildingFactory):
    """Default game factory for buildings."""

    BUILDING_COSTS = {
        "университет": 100,
        "библиотека": 80,
        "парк": 60,
        "спортзал": 90,
        "офис": 120,
        "кафе": 70,
        "больница": 150,
        "музей": 110,
    }

    BUILDING_CATEGORIES = {
        "университет": TaskCategory.STUDY,
        "библиотека": TaskCategory.STUDY,
        "спортзал": TaskCategory.HEALTH,
        "больница": TaskCategory.HEALTH,
        "парк": TaskCategory.PERSONAL,
        "кафе": TaskCategory.PERSONAL,
        "офис": TaskCategory.WORK,
        "музей": TaskCategory.PERSONAL,
    }

    PRIMARY_BUILDINGS_BY_CATEGORY = {
        TaskCategory.STUDY: "университет",
        TaskCategory.WORK: "офис",
        TaskCategory.HEALTH: "спортзал",
        TaskCategory.PERSONAL: "кафе",
    }

    def create_building(
        self,
        building_type: str,
        user_id: int,
        position_x: int,
        position_y: int,
    ) -> Building:
        """Creates a standard building."""
        if building_type not in self.BUILDING_COSTS:
            raise ValueError(f"Unknown building type: {building_type}")

        return Building(
            user_id=user_id,
            building_type=building_type,
            category=self._get_category(building_type),
            level=1,
            position_x=position_x,
            position_y=position_y,
        )

    def get_building_cost(self, building_type: str, level: int = 1) -> int:
        """Calculates building cost for the given level."""
        if building_type not in self.BUILDING_COSTS:
            raise ValueError(f"Unknown building type: {building_type}")

        base_cost = self.BUILDING_COSTS[building_type]
        return int(base_cost * (level * 1.5))

    def get_available_buildings(self) -> list[str]:
        """Returns available building types."""
        return list(self.BUILDING_COSTS.keys())

    def get_progress_building_type(self, category: TaskCategory) -> str:
        """Returns the canonical progression building for the category."""
        try:
            return self.PRIMARY_BUILDINGS_BY_CATEGORY[category]
        except KeyError as exc:
            raise ValueError(f"Unsupported category: {category}") from exc

    def _get_category(self, building_type: str) -> TaskCategory:
        """Returns the category for the building type."""
        return self.BUILDING_CATEGORIES.get(building_type, TaskCategory.PERSONAL)

    def get_building_info(self, building_type: str) -> dict:
        """Returns building metadata."""
        if building_type not in self.BUILDING_COSTS:
            raise ValueError(f"Unknown building type: {building_type}")

        return {
            "type": building_type,
            "base_cost": self.BUILDING_COSTS[building_type],
            "category": self._get_category(building_type).value,
        }
