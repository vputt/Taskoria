from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.city_progression_policy import CityProgressionPolicy
from app.factories.building_factory import StandardBuildingFactory
from app.models.building import Building
from app.models.task import TaskCategory
from app.services.city_service import CityService


class FakeDB:
    def __init__(self, repo):
        self.repo = repo

    def add(self, building):
        if getattr(building, "id", None) is None:
            building.id = len(self.repo.buildings) + 1
        self.repo.buildings.append(building)

    def commit(self):
        return None

    def refresh(self, _obj):
        return None

    def rollback(self):
        return None


class FakeBuildingRepo:
    def __init__(self, buildings=None):
        self.buildings = list(buildings or [])
        self.db = FakeDB(self)

    def get_user_buildings(self, user_id):
        return [building for building in self.buildings if building.user_id == user_id]

    def get_by_user_and_position(self, user_id, position_x, position_y):
        for building in self.buildings:
            if (
                building.user_id == user_id
                and building.position_x == position_x
                and building.position_y == position_y
            ):
                return building
        return None

    def get_by_user_and_category(self, user_id, category):
        matches = [
            building
            for building in self.buildings
            if building.user_id == user_id and building.category == category
        ]
        return sorted(matches, key=lambda building: building.id or 0)[0] if matches else None


class FakeTaskRepo:
    def __init__(self, counts=None):
        self.counts = counts or {}

    def count_completed_by_category(self, user_id, category):
        return self.counts.get((user_id, category), 0)


def make_city_service(task_counts, buildings=None):
    building_repo = FakeBuildingRepo(buildings=buildings)
    task_repo = FakeTaskRepo(task_counts)

    return CityService(
        user_repo=None,
        building_repo=building_repo,
        task_repo=task_repo,
        building_factory=StandardBuildingFactory(),
        progression_policy=CityProgressionPolicy(),
    ), building_repo


def test_get_city_state_creates_category_progress_building_for_first_completed_task():
    city_service, building_repo = make_city_service({
        (1, TaskCategory.STUDY): 1,
    })

    city = city_service.get_city_state(1)

    assert len(building_repo.buildings) == 1
    assert city["total_buildings"] == 1
    assert city["total_level"] == 1
    assert city["category_breakdown"] == {"учеба": 1}

    building = city["buildings"][0]
    assert building.building_type == "университет"
    assert building.category == TaskCategory.STUDY
    assert building.level == 1


def test_sync_city_progress_upgrades_existing_category_building_by_completed_tasks():
    existing_building = Building(
        user_id=1,
        building_type="университет",
        category=TaskCategory.STUDY,
        level=1,
        position_x=0,
        position_y=0,
    )
    existing_building.id = 10

    city_service, building_repo = make_city_service(
        {(1, TaskCategory.STUDY): 20},
        buildings=[existing_building],
    )

    city_service.sync_city_progress(1)

    assert len(building_repo.buildings) == 1
    assert building_repo.buildings[0].level == 3
