from datetime import date, timedelta
from pathlib import Path
import sys
from types import SimpleNamespace
from unittest.mock import Mock

import pytest
from jose import jwt

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.config import settings
from app.models.user import User
from app.schemas.user import UserCreate
from app.services.auth_service import AuthService
from app.services.reward_service import RewardService
from app.states.streak_state import (
    ActiveStreakState,
    BrokenStreakState,
    NewStreakState,
    StreakManager,
)
from app.core.event_bus import EventType


def make_user(**overrides):
    values = {
        "id": 1,
        "email": "user@example.com",
        "username": "user",
        "password_hash": "secret",
        "level": 1,
        "xp": 0,
        "coins": 0,
        "streak": 0,
        "last_activity_date": None,
    }
    values.update(overrides)
    return SimpleNamespace(**values)


def test_auth_register_user_creates_user_with_plain_hash_for_dev_mode():
    repo = Mock()
    repo.email_exists.return_value = False
    repo.create.side_effect = lambda payload: SimpleNamespace(id=7, **payload)
    service = AuthService(repo)

    user = service.register_user(UserCreate(
        email="new@example.com",
        username="newbie",
        password="plain-password",
    ))

    repo.create.assert_called_once_with({
        "email": "new@example.com",
        "username": "newbie",
        "password_hash": "plain-password",
    })
    assert user.id == 7


def test_auth_register_user_rejects_duplicate_email():
    repo = Mock()
    repo.email_exists.return_value = True

    with pytest.raises(ValueError, match="Email already registered"):
        AuthService(repo).register_user(UserCreate(
            email="used@example.com",
            username="used",
            password="secret123",
        ))


def test_authenticate_user_success_wrong_password_and_missing_user():
    user = make_user(password_hash="secret")
    repo = Mock()
    service = AuthService(repo)

    repo.get_by_email.return_value = user
    assert service.authenticate_user("user@example.com", "secret") is user
    assert service.authenticate_user("user@example.com", "bad") is None

    repo.get_by_email.return_value = None
    assert service.authenticate_user("missing@example.com", "secret") is None


def test_create_access_token_contains_payload_and_expiration():
    token = AuthService(Mock()).create_access_token(
        {"sub": "42"},
        expires_delta=timedelta(minutes=5),
    )

    decoded = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    assert decoded["sub"] == "42"
    assert "exp" in decoded


def test_reward_service_applies_rewards_without_level_up():
    user = User(
        id=1,
        email="user@example.com",
        username="user",
        password_hash="secret",
        level=1,
        xp=10,
        coins=5,
    )
    repo = Mock()
    repo.get.return_value = user
    event_bus = Mock()

    result = RewardService(user_repo=repo, event_bus=event_bus).apply_rewards(1, xp=20, coins=7)

    assert result == {
        "xp_earned": 20,
        "coins_earned": 7,
        "level_up": False,
        "new_level": None,
        "total_xp": 30,
        "total_coins": 12,
    }
    repo.update.assert_called_once_with(user, {})
    event_bus.publish.assert_not_called()


def test_reward_service_publishes_level_up_event():
    user = User(
        id=1,
        email="user@example.com",
        username="user",
        password_hash="secret",
        level=1,
        xp=90,
        coins=0,
    )
    repo = Mock()
    repo.get.return_value = user
    event_bus = Mock()

    result = RewardService(user_repo=repo, event_bus=event_bus).apply_rewards(1, xp=25, coins=3)

    assert result["level_up"] is True
    assert result["new_level"] == 2
    event_bus.publish.assert_called_once_with(EventType.LEVEL_UP, {
        "user_id": 1,
        "old_level": 1,
        "new_level": 2,
    })


def test_reward_service_rejects_missing_user_and_facade_calculates_first():
    repo = Mock()
    repo.get.return_value = None
    with pytest.raises(ValueError, match="User not found"):
        RewardService(user_repo=repo).apply_rewards(404, xp=1, coins=1)

    calculator = Mock()
    calculator.calculate.return_value = (33, 12)
    user = User(
        id=1,
        email="user@example.com",
        username="user",
        password_hash="secret",
        level=1,
        xp=0,
        coins=0,
    )
    repo.get.return_value = user

    result = RewardService(calculator=calculator, user_repo=repo).calculate_and_apply_rewards(
        user_id=1,
        task_description="demo",
        priority="medium",
        subtasks_count=2,
        category="work",
    )

    assert result["xp_earned"] == 33
    assert result["coins_earned"] == 12
    calculator.calculate.assert_called_once()


def test_streak_states_cover_new_active_same_day_next_day_and_broken_paths():
    today = date(2026, 5, 20)
    user = make_user(streak=0, last_activity_date=None)

    state = NewStreakState().update(user, today)
    assert isinstance(state, ActiveStreakState)
    assert user.streak == 1
    assert NewStreakState().get_state_name() == "new"

    state = state.update(user, today)
    assert isinstance(state, ActiveStreakState)
    assert user.streak == 1

    state = state.update(user, today + timedelta(days=1))
    assert isinstance(state, ActiveStreakState)
    assert user.streak == 2

    state = state.update(user, today + timedelta(days=4))
    assert isinstance(state, BrokenStreakState)
    assert user.streak == 1
    assert state.get_state_name() == "broken"

    state = state.update(user, today + timedelta(days=5))
    assert isinstance(state, ActiveStreakState)
    assert user.streak == 1


def test_streak_manager_selects_state_from_user_history():
    today = date(2026, 5, 20)
    manager = StreakManager()

    user = make_user(streak=3, last_activity_date=today - timedelta(days=1))
    assert manager.update_streak(user, today) == 4
    assert manager.get_current_state_name() == "active"

    user = make_user(streak=3, last_activity_date=today - timedelta(days=3))
    assert manager.update_streak(user, today) == 1
    assert manager.get_current_state_name() == "active"
