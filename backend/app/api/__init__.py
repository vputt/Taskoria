"""
API endpoints
"""
from fastapi import APIRouter

from app.api import auth, city, shop, subtasks, tasks, users

api_router = APIRouter()

# Подключаем роутеры
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(tasks.router, prefix="/tasks", tags=["tasks"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(subtasks.router, prefix="/tasks/{task_id}/subtasks", tags=["subtasks"])
api_router.include_router(city.router, prefix="/city", tags=["city"])
api_router.include_router(shop.router, prefix="/shop", tags=["shop"])
