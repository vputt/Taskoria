"""
Application event observers.
"""
import logging
from typing import Callable

from app.core.city_progression_policy import CityProgressionPolicy
from app.core.event_bus import EventType, event_bus
from app.database import SessionLocal
from app.factories.building_factory import StandardBuildingFactory
from app.repositories.building_repository import BuildingRepository
from app.repositories.task_repository import TaskRepository
from app.repositories.user_repository import UserRepository
from app.services.city_service import CityService

logger = logging.getLogger(__name__)


class CityProgressObserver:
    """Synchronizes city progress after task completion."""

    def __init__(
        self,
        session_factory: Callable = SessionLocal,
        building_factory: StandardBuildingFactory | None = None,
        progression_policy: CityProgressionPolicy | None = None,
    ):
        self.session_factory = session_factory
        self.building_factory = building_factory or StandardBuildingFactory()
        self.progression_policy = progression_policy or CityProgressionPolicy()

    def on_task_completed(self, data: dict) -> None:
        """Updates city progress for the user from the event payload."""
        user_id = data.get("user_id")
        if user_id is None:
            logger.warning("TASK_COMPLETED event received without user_id")
            return

        db = self.session_factory()
        try:
            city_service = CityService(
                user_repo=UserRepository(db),
                building_repo=BuildingRepository(db),
                task_repo=TaskRepository(db),
                building_factory=self.building_factory,
                progression_policy=self.progression_policy,
            )
            city_service.sync_city_progress(user_id)
        finally:
            db.close()


_city_progress_observer = CityProgressObserver()
_observers_registered = False


def register_event_observers() -> None:
    """Registers application observers once per process."""
    global _observers_registered

    if _observers_registered:
        return

    event_bus.subscribe(EventType.TASK_COMPLETED, _city_progress_observer.on_task_completed)
    _observers_registered = True
