"""
Клиент для работы с GigaChat API (ИИ) через REST.

Обеспечивает:
- Получение Access token через OAuth
- Кэширование токена (действует 30 минут)
- Отправку запросов к API для разбиения задач и оценки сложности
"""
import httpx
import logging
import time
import uuid
from typing import Optional
from app.config import settings

logger = logging.getLogger(__name__)


class GigaChatClient:
    """
    Клиент для работы с GigaChat REST API (ИИ).
    
    Обеспечивает автоматическое получение и обновление Access token.
    """
    
    def __init__(
        self,
        authorization_key: str,
        oauth_url: str = None,
        api_url: str = None,
        scope: str = None
    ):
        """
        Инициализация клиента.
        
        Args:
            authorization_key: Authorization key для OAuth
            oauth_url: URL для получения токена
            api_url: Базовый URL API
            scope: Scope для OAuth запроса
        """
        self.authorization_key = authorization_key
        self.oauth_url = oauth_url or settings.GIGACHAT_OAUTH_URL
        self.api_url = api_url or settings.GIGACHAT_API_URL
        self.scope = scope or settings.GIGACHAT_SCOPE
        
        # Кэш токена
        self._access_token: Optional[str] = None
        self._token_expires_at: float = 0
        
        # HTTP клиент
        self._client = httpx.AsyncClient(timeout=30.0, verify=False)
    
    async def _get_access_token(self) -> str:
        """
        Получает Access token через OAuth.
        
        Returns:
            Access token
        """
        # Проверяем, не истек ли токен
        if self._access_token and time.time() < self._token_expires_at:
            return self._access_token
        
        try:
            # Генерируем RqUID (Request Unique ID)
            rquid = str(uuid.uuid4())
            
            # Запрос на получение токена
            response = await self._client.post(
                self.oauth_url,
                headers={
                    "Content-Type": "application/x-www-form-urlencoded",
                    "Accept": "application/json",
                    "RqUID": rquid,
                    "Authorization": f"Basic {self.authorization_key}"
                },
                data={"scope": self.scope}
            )
            
            response.raise_for_status()
            data = response.json()
            
            # Извлекаем токен
            access_token = data.get("access_token")
            expires_in = data.get("expires_in", 1800)  # По умолчанию 30 минут
            
            if not access_token:
                raise ValueError("Access token not found in response")
            
            # Сохраняем токен с запасом времени (минус 60 секунд для безопасности)
            self._access_token = access_token
            self._token_expires_at = time.time() + expires_in - 60
            
            logger.info(f"Access token obtained, expires in {expires_in}s")
            return access_token
            
        except httpx.HTTPStatusError as e:
            logger.error(f"Failed to get access token: {e.response.status_code} - {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"Error getting access token: {e}")
            raise
    
    async def chat(self, messages: list, model: str = "GigaChat-Pro") -> dict:
        """
        Отправляет запрос к GigaChat API для чата (ИИ).
        
        Args:
            messages: Список сообщений в формате [{"role": "user", "content": "текст"}]
            model: Название модели (по умолчанию "GigaChat-Pro")
            
        Returns:
            Ответ от API
        """
        access_token = await self._get_access_token()
        
        try:
            # API использует /api/v1/chat/completions
            response = await self._client.post(
                f"{self.api_url}/chat/completions",
                headers={
                    "Accept": "application/json",
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": model,
                    "messages": messages,
                    "temperature": 0.7,
                    "max_tokens": 2000
                }
            )
            
            response.raise_for_status()
            return response.json()
            
        except httpx.HTTPStatusError as e:
            logger.error(f"API error: {e.response.status_code} - {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"Error calling GigaChat API: {e}")
            raise
    
    async def get_models(self) -> dict:
        """
        Получает список доступных моделей.
        
        Returns:
            Список моделей
        """
        access_token = await self._get_access_token()
        
        try:
            response = await self._client.get(
                f"{self.api_url}/models",
                headers={
                    "Accept": "application/json",
                    "Authorization": f"Bearer {access_token}"
                }
            )
            
            response.raise_for_status()
            return response.json()
            
        except httpx.HTTPStatusError as e:
            logger.error(f"Models API error: {e.response.status_code} - {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"Error getting models: {e}")
            raise
    
    async def close(self):
        """Закрывает HTTP клиент"""
        await self._client.aclose()
    
    async def __aenter__(self):
        """Поддержка async context manager"""
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Поддержка async context manager"""
        await self.close()
