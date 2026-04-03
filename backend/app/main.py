"""
Главный файл FastAPI приложения.

Применяет все настроенные паттерны проектирования.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging

from app.config import settings
from app.api import api_router
from app.core.observers import register_event_observers
from app.database import init_db

# Настройка логирования
logging.basicConfig(
    level=logging.INFO if settings.DEBUG else logging.WARNING,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Создание FastAPI приложения
app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Геймифицированное мобильное приложение для управления задачами и визуализации прогресса — Taskoria (Backend API)",
    version="1.0.0",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене указать конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event():
    """
    Событие запуска приложения.
    
    Инициализирует базу данных и другие компоненты.
    """
    logger.info("Starting Taskoria API...")
    logger.info(f"Debug mode: {settings.DEBUG}")
    
    # Инициализация БД (создание таблиц если их нет)
    try:
        init_db()
        register_event_observers()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")


@app.on_event("shutdown")
async def shutdown_event():
    """Событие остановки приложения"""
    logger.info("Shutting down Taskoria API...")


@app.get("/")
async def root():
    """Корневой endpoint"""
    return {
        "message": "Taskoria API",
        "version": "1.0.0",
        "docs": f"{settings.API_V1_STR}/docs"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint для мониторинга"""
    return {
        "status": "healthy",
        "service": settings.PROJECT_NAME
    }


# Подключение API роутеров
app.include_router(api_router, prefix=settings.API_V1_STR)


# Глобальный обработчик ошибок
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """
    Глобальный обработчик исключений.
    
    Логирует ошибки и возвращает понятный ответ клиенту.
    """
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error" if not settings.DEBUG else str(exc)
        }
    )


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="info" if settings.DEBUG else "warning"
    )
