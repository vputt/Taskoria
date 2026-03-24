"""
Pydantic schemas for city and building APIs.
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models.task import TaskCategory


class BuildingBase(BaseModel):
    """Base building schema."""

    building_type: str
    category: TaskCategory
    position_x: int = Field(..., ge=0)
    position_y: int = Field(..., ge=0)


class BuildingCreate(BuildingBase):
    """Internal schema for building creation."""


class BuildingCreateRequest(BaseModel):
    """Input schema for manual building purchase."""

    building_type: str
    position_x: int = Field(..., ge=0)
    position_y: int = Field(..., ge=0)


class BuildingResponse(BuildingBase):
    """Response schema with building data."""

    id: int
    user_id: int
    level: int
    built_at: datetime
    upgraded_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)


class BuildingPurchaseResponse(BaseModel):
    """Response after purchasing a building."""

    building: BuildingResponse
    cost: int
    balance_after: int


class BuildingUpgradeResponse(BaseModel):
    """Response after upgrading a building."""

    building: BuildingResponse
    cost: int
    new_level: int
    balance_after: int


class CityResponse(BaseModel):
    """Current city state."""

    user_id: int
    buildings: list[BuildingResponse] = Field(default_factory=list)
    total_buildings: int
    total_level: int
    category_breakdown: dict[str, int] = Field(default_factory=dict)
    average_level: float = 0.0
