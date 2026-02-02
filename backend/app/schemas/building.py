"""
Pydantic схемы для Building
"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from app.models.task import TaskCategory


class BuildingBase(BaseModel):
    """Базовая схема здания"""
    building_type: str
    category: TaskCategory
    position_x: int = Field(..., ge=0)
    position_y: int = Field(..., ge=0)


class BuildingCreate(BuildingBase):
    """Схема создания здания"""
    pass


class BuildingResponse(BuildingBase):
    """Схема ответа с данными здания"""
    id: int
    user_id: int
    level: int
    built_at: datetime
    upgraded_at: Optional[datetime]
    
    class Config:
        from_attributes = True


class BuildingUpgradeResponse(BaseModel):
    """Ответ после улучшения здания"""
    building: BuildingResponse
    cost: int
    new_level: int


class CityResponse(BaseModel):
    """Схема состояния города"""
    user_id: int
    buildings: list[BuildingResponse]
    total_buildings: int
    total_level: int
