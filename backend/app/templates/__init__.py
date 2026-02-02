"""
Template Method Pattern для алгоритмов
"""
from app.templates.reward_calculator import (
    RewardCalculator,
    StandardRewardCalculator,
    PremiumRewardCalculator
)

__all__ = [
    "RewardCalculator",
    "StandardRewardCalculator",
    "PremiumRewardCalculator"
]
