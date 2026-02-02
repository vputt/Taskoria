"""
Сервис аутентификации и авторизации
"""
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserCreate


class AuthService:
    """
    Сервис аутентификации (с применением DI).
    
    Применяемый паттерн: Dependency Injection
    - Репозиторий внедряется через конструктор
    - Упрощает тестирование (можно использовать mock-репозитории)
    
    ВНИМАНИЕ: Временно отключено хеширование паролей для разработки.
    В продакшене необходимо включить безопасное хеширование!
    """
    
    def __init__(self, user_repo: UserRepository):
        """
        Инициализация сервиса.
        
        Args:
            user_repo: Репозиторий пользователей (DI)
        """
        self.user_repo = user_repo
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """
        Проверяет пароль.
        
        Args:
            plain_password: Пароль в открытом виде
            hashed_password: Хранимый пароль (временно без хеширования)
            
        Returns:
            bool: True если пароль верный
        """
        # ВРЕМЕННО: Простое сравнение без хеширования (только для разработки!)
        return plain_password == hashed_password
    
    def get_password_hash(self, password: str) -> str:
        """
        Хеширует пароль.
        
        Args:
            password: Пароль в открытом виде (любой длины)
            
        Returns:
            str: Пароль (временно без хеширования)
        """
        # ВРЕМЕННО: Возвращаем пароль как есть (только для разработки!)
        # В продакшене здесь должно быть безопасное хеширование
        return password
    
    def create_access_token(
        self,
        data: dict,
        expires_delta: Optional[timedelta] = None
    ) -> str:
        """
        Создает JWT токен.
        
        Args:
            data: Данные для токена
            expires_delta: Время жизни токена
            
        Returns:
            str: JWT токен
        """
        to_encode = data.copy()
        
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(
                minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
            )
        
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(
            to_encode,
            settings.SECRET_KEY,
            algorithm=settings.ALGORITHM
        )
        return encoded_jwt
    
    def register_user(self, user_data: UserCreate) -> User:
        """
        Регистрирует нового пользователя.
        
        Args:
            user_data: Данные пользователя
            
        Returns:
            User: Созданный пользователь
            
        Raises:
            ValueError: Если email уже существует
        """
        # Проверка существования email
        if self.user_repo.email_exists(user_data.email):
            raise ValueError("Email already registered")
        
        # Хеширование пароля
        hashed_password = self.get_password_hash(user_data.password)
        
        # Создание пользователя
        user = self.user_repo.create({
            "email": user_data.email,
            "username": user_data.username,
            "password_hash": hashed_password
        })
        
        return user
    
    def authenticate_user(self, email: str, password: str) -> Optional[User]:
        """
        Аутентифицирует пользователя.
        
        Args:
            email: Email пользователя
            password: Пароль
        
        Returns:
            User или None если аутентификация не удалась
        """
        user = self.user_repo.get_by_email(email)
        
        if not user:
            return None
        
        if not self.verify_password(password, user.password_hash):
            return None
        
        return user
    
    def get_user_by_id(self, user_id: int) -> Optional[User]:
        """
        Получает пользователя по ID.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            User или None
        """
        return self.user_repo.get(user_id)
