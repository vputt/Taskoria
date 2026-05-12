from pathlib import Path
import sys
from unittest.mock import AsyncMock, Mock

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.core.event_bus import EventBus, EventType
from app.core.observers import CityProgressObserver
from app.models.user import User
from app.repositories.base_repository import BaseRepository
from app.services.ai_service import AIService
from app.strategies.ai_strategy import GigaChatStrategy, MockAIStrategy


class FakeQuery:
    def __init__(self, first_result=None, all_result=None, count_result=0):
        self.first_result = first_result
        self.all_result = all_result or []
        self.count_result = count_result
        self.offset_value = None
        self.limit_value = None

    def filter(self, *args):
        return self

    def order_by(self, *args):
        return self

    def offset(self, value):
        self.offset_value = value
        return self

    def limit(self, value):
        self.limit_value = value
        return self

    def first(self):
        return self.first_result

    def all(self):
        return self.all_result

    def count(self):
        return self.count_result


class FakeDB:
    def __init__(self, query):
        self.query_obj = query
        self.added = []
        self.deleted = []
        self.commits = 0
        self.refreshed = []

    def query(self, _model):
        return self.query_obj

    def add(self, obj):
        self.added.append(obj)

    def commit(self):
        self.commits += 1

    def refresh(self, obj):
        self.refreshed.append(obj)

    def delete(self, obj):
        self.deleted.append(obj)


def test_event_bus_subscribe_publish_unsubscribe_and_handler_errors():
    bus = EventBus()
    bus.clear_subscribers()
    received = []

    def handler(data):
        received.append(data)

    def broken_handler(_data):
        raise RuntimeError("boom")

    bus.subscribe(EventType.TASK_CREATED, handler)
    bus.subscribe(EventType.TASK_CREATED, handler)
    bus.subscribe(EventType.TASK_CREATED, broken_handler)
    bus.publish(EventType.TASK_CREATED, {"task_id": 1})

    assert received == [{"task_id": 1}]

    bus.unsubscribe(EventType.TASK_CREATED, handler)
    bus.publish(EventType.TASK_CREATED, {"task_id": 2})
    assert received == [{"task_id": 1}]

    bus.clear_subscribers()
    assert bus._subscribers == {}


def test_city_progress_observer_ignores_missing_user_and_closes_session(monkeypatch):
    observer = CityProgressObserver(session_factory=Mock())
    observer.on_task_completed({})
    observer.session_factory.assert_not_called()

    session = Mock()
    session_factory = Mock(return_value=session)
    sync = Mock()

    class FakeCityService:
        def __init__(self, **_kwargs):
            pass

        def sync_city_progress(self, user_id):
            sync(user_id)

    monkeypatch.setattr("app.core.observers.CityService", FakeCityService)

    observer = CityProgressObserver(session_factory=session_factory)
    observer.on_task_completed({"user_id": 42})

    sync.assert_called_once_with(42)
    session.close.assert_called_once()


def test_base_repository_crud_methods_with_fake_db():
    existing = User(id=1, email="user@example.com", username="user", password_hash="secret")
    query = FakeQuery(first_result=existing, all_result=[existing], count_result=1)
    db = FakeDB(query)
    repo = BaseRepository(User, db)

    assert repo.get(1) is existing
    assert repo.get_all(skip=2, limit=3) == [existing]
    assert query.offset_value == 2
    assert query.limit_value == 3
    assert repo.count() == 1
    assert repo.exists(1) is True

    created = repo.create({
        "email": "new@example.com",
        "username": "new",
        "password_hash": "secret",
    })
    assert created in db.added
    assert db.commits == 1

    repo.update(existing, {"username": "updated", "missing": "ignored", "email": None})
    assert existing.username == "updated"
    assert existing.email == "user@example.com"
    assert db.commits == 2

    assert repo.delete(1) is True
    assert existing in db.deleted
    assert db.commits == 3

    repo.db = FakeDB(FakeQuery(first_result=None))
    assert repo.delete(404) is False


@pytest.mark.asyncio
async def test_ai_service_delegates_to_strategy_and_allows_strategy_replacement():
    service = AIService(strategy=MockAIStrategy())

    assert len(await service.split_task("demo", "medium")) == 2
    assert await service.estimate_difficulty("demo") == "средняя"
    assert await service.estimate_rewards("demo", "medium", 30, "medium") == {"xp": 30, "coins": 15}

    strategy = Mock()
    strategy.split_task = AsyncMock(return_value=[])
    strategy.estimate_difficulty = AsyncMock(return_value="custom")
    strategy.estimate_rewards = AsyncMock(return_value={"xp": 1, "coins": 1})
    service.set_strategy(strategy)

    assert await service.split_task("demo", "low") == []
    assert await service.estimate_difficulty("demo") == "custom"
    assert await service.estimate_rewards("demo", "easy", 5, "low") == {"xp": 1, "coins": 1}


def test_gigachat_strategy_parsers_and_fallbacks_without_network():
    strategy = GigaChatStrategy("test-key")

    parsed = strategy._parse_response({
        "choices": [{
            "message": {
                "content": '[{"title": "A", "description": "B", "estimated_time": 10}]'
            }
        }]
    })
    assert parsed == [{
        "title": "A",
        "description": "B",
        "estimated_time": 10,
        "order_index": 0,
    }]

    rewards = strategy._parse_rewards({
        "choices": [{"message": {"content": '{"xp": 55, "coins": 22}'}}]
    })
    assert rewards == {"xp": 55, "coins": 22}

    assert strategy._parse_rewards({"choices": []}) == {"xp": 15, "coins": 8}
    assert strategy._parse_response({"choices": []})[0]["order_index"] == 0
    assert strategy._parse_difficulty({"choices": []}) == "средняя"
    assert strategy._parse_difficulty({"choices": [{"message": {"content": "easy text"}}]}) == "средняя"

    fallback = strategy._get_fallback_rewards("unknown", 600)
    assert fallback == {"xp": 230, "coins": 115}


@pytest.mark.asyncio
async def test_gigachat_strategy_async_methods_use_fallback_when_client_fails():
    strategy = GigaChatStrategy("bad-key")
    strategy._get_client = AsyncMock(side_effect=RuntimeError("offline"))

    subtasks = await strategy.split_task("offline task", "high")
    difficulty = await strategy.estimate_difficulty("offline task")
    rewards = await strategy.estimate_rewards("offline task", "unknown", 30, "medium")

    assert len(subtasks) == 2
    assert difficulty == "средняя"
    assert rewards == {"xp": 40, "coins": 20}
