"""
Конфигурация приложения с применением Singleton Pattern.

Паттерн: Singleton
Обоснование: Гарантирует единственный экземпляр настроек приложения,
предотвращает множественное чтение .env файла и обеспечивает 
глобальный доступ к конфигурации.
"""
from typing import Optional

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Singleton для конфигурации приложения.
    
    Применяемый паттерн: Singleton
    - Единственный экземпляр на всё приложение
    - Ленивая инициализация при первом обращении
    - Глобальная точка доступа через переменную settings
    """
    
    # Database
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/productivity_db"
    
    # Security
    SECRET_KEY: str = "your-secret-key-here-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Интеграция с ИИ (GigaChat API) для разбиения задач и оценки сложности
    GIGACHAT_AUTHORIZATION_KEY: str = ""  # Ключ авторизации для получения Access token
    GIGACHAT_API_URL: str = "https://gigachat.devices.sberbank.ru/api/v1"
    GIGACHAT_OAUTH_URL: str = "https://ngw.devices.sberbank.ru:9443/api/v2/oauth"
    GIGACHAT_SCOPE: str = "GIGACHAT_API_PERS"
    GIGACHAT_ACCESS_TOKEN_TTL: int = 1800  # 30 минут в секундах
    
    # Cache
    REDIS_URL: str = "redis://localhost:6379"
    CACHE_TTL: int = 3600
    
    # Application
    DEBUG: bool = True
    API_V1_STR: str = "/api"
    PROJECT_NAME: str = "Taskoria API"

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
    )

    @field_validator("DEBUG", mode="before")
    @classmethod
    def normalize_debug(cls, value: bool | str) -> bool | str:
        """
        Принимает типовые строковые режимы окружения.
        Это делает конфиг устойчивее к значениям вроде DEBUG=release.
        """
        if isinstance(value, bool):
            return value

        if isinstance(value, str):
            normalized = value.strip().lower()
            truthy_values = {"1", "true", "yes", "on", "debug", "dev", "development"}
            falsy_values = {"0", "false", "no", "off", "release", "prod", "production"}

            if normalized in truthy_values:
                return True
            if normalized in falsy_values:
                return False

        return value


# Singleton instance - единственный экземпляр настроек
settings = Settings()
