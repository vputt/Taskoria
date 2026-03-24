"""
Domain service for city and building mechanics.
"""
from sqlalchemy.exc import IntegrityError

from app.builders.city_builder import CityBuilder
from app.core.city_progression_policy import CityProgressionPolicy
from app.factories.building_factory import StandardBuildingFactory
from app.models.building import Building
from app.models.task import TaskCategory
from app.repositories.building_repository import BuildingRepository
from app.repositories.task_repository import TaskRepository
from app.repositories.user_repository import UserRepository


class CityService:
    """Coordinates manual building actions and category-based city progression."""

    def __init__(
        self,
        user_repo: UserRepository,
        building_repo: BuildingRepository,
        task_repo: TaskRepository,
        building_factory: StandardBuildingFactory,
        progression_policy: CityProgressionPolicy,
    ):
        self.user_repo = user_repo
        self.building_repo = building_repo
        self.task_repo = task_repo
        self.building_factory = building_factory
        self.progression_policy = progression_policy
        self.db = building_repo.db

    def get_city_state(self, user_id: int) -> dict:
        """Returns the current city state for the user."""
        self.sync_city_progress(user_id)
        buildings = self.building_repo.get_user_buildings(user_id)
        return CityBuilder(user_id=user_id).add_buildings(buildings).build()

    def sync_city_progress(self, user_id: int) -> list[Building]:
        """Synchronizes category buildings with completed task progress."""
        synchronized_buildings: list[Building] = []
        has_changes = False

        for category in TaskCategory:
            completed_tasks = self.task_repo.count_completed_by_category(user_id, category)
            target_level = self.progression_policy.get_target_level(completed_tasks)
            if target_level == 0:
                continue

            building = self.building_repo.get_by_user_and_category(user_id, category)
            if building is None:
                building = self._create_progress_building(user_id, category, target_level)
                has_changes = True
            elif target_level > building.level:
                self._upgrade_progress_building(building, target_level)
                has_changes = True

            synchronized_buildings.append(building)

        if has_changes:
            self.db.commit()
            for building in synchronized_buildings:
                self.db.refresh(building)

        return synchronized_buildings

    def build_building(self, user_id: int, building_type: str, x: int, y: int) -> tuple[Building, int, int]:
        """Builds a new building in the selected cell by spending coins."""
        user = self.user_repo.get(user_id)
        if not user:
            raise ValueError("User not found")

        if self.building_repo.get_by_user_and_position(user_id, x, y):
            raise ValueError("Cell is already occupied")

        try:
            cost = self.building_factory.get_building_cost(building_type=building_type, level=1)
            building = self.building_factory.create_building(
                building_type=building_type,
                user_id=user_id,
                position_x=x,
                position_y=y,
            )
        except ValueError as exc:
            raise ValueError(str(exc)) from exc

        if user.coins < cost:
            raise ValueError("Insufficient funds")

        user.coins -= cost

        try:
            self.db.add(building)
            self.db.commit()
        except IntegrityError as exc:
            self.db.rollback()
            raise ValueError("Cell is already occupied") from exc
        except Exception:
            self.db.rollback()
            raise

        self.db.refresh(building)
        self.db.refresh(user)
        return building, cost, user.coins

    def upgrade_building(self, user_id: int, building_id: int) -> tuple[Building, int, int]:
        """Upgrades a user's building by spending coins."""
        user = self.user_repo.get(user_id)
        if not user:
            raise ValueError("User not found")

        building = self.building_repo.get(building_id)
        if not building:
            raise ValueError("Building not found")

        if building.user_id != user_id:
            raise PermissionError("Not authorized to upgrade this building")

        cost = building.get_upgrade_cost()
        if user.coins < cost:
            raise ValueError("Insufficient funds")

        user.coins -= cost
        building.upgrade()

        try:
            self.db.commit()
        except Exception:
            self.db.rollback()
            raise

        self.db.refresh(building)
        self.db.refresh(user)
        return building, cost, user.coins

    def _create_progress_building(
        self,
        user_id: int,
        category: TaskCategory,
        target_level: int,
    ) -> Building:
        """Creates a category progression building at its resolved position."""
        position_x, position_y = self._resolve_progress_position(user_id, category)
        building = self.building_factory.create_building(
            building_type=self.building_factory.get_progress_building_type(category),
            user_id=user_id,
            position_x=position_x,
            position_y=position_y,
        )
        self._upgrade_progress_building(building, target_level)
        self.db.add(building)
        return building

    @staticmethod
    def _upgrade_progress_building(building: Building, target_level: int) -> None:
        """Upgrades the building until it reaches the target level."""
        while building.level < target_level:
            building.upgrade()

    def _resolve_progress_position(self, user_id: int, category: TaskCategory) -> tuple[int, int]:
        """Returns a stable position for the category building."""
        preferred_position = self.progression_policy.get_anchor_position(category)
        if not self.building_repo.get_by_user_and_position(user_id, *preferred_position):
            return preferred_position

        occupied_positions = {
            (building.position_x, building.position_y)
            for building in self.building_repo.get_user_buildings(user_id)
        }
        return self._find_next_free_position(occupied_positions)

    @staticmethod
    def _find_next_free_position(occupied_positions: set[tuple[int, int]]) -> tuple[int, int]:
        """Finds the next free non-negative cell without a fixed grid limit."""
        radius = 0
        while True:
            for x in range(radius + 1):
                for y in range(radius + 1):
                    candidate = (x, y)
                    if candidate not in occupied_positions:
                        return candidate
            radius += 1
