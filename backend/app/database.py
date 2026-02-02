"""
Подключение к базе данных с применением Singleton Pattern.

Паттерн: Singleton
Обоснование: Гарантирует единственный экземпляр подключения к БД,
предотвращает утечки ресурсов и обеспечивает эффективное управление
пулом соединений.
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from typing import Generator

from app.config import settings


# Singleton для database engine
# Создается один раз при импорте модуля
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,  # Проверка соединения перед использованием
    pool_size=10,        # Размер пула соединений
    max_overflow=20,     # Максимальное количество дополнительных соединений
    echo=settings.DEBUG  # Логирование SQL запросов в режиме отладки
)

# Session factory - фабрика для создания сессий
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False
)

# Базовый класс для всех моделей
Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """
    Dependency Injection для получения сессии БД.
    
    Применяемый паттерн: Dependency Injection
    Используется FastAPI для автоматического управления жизненным циклом сессии.
    
    Yields:
        Session: Сессия базы данных
        
    Example:
        @app.get("/items/")
        def read_items(db: Session = Depends(get_db)):
            return db.query(Item).all()
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """
    Инициализация базы данных.
    Создает все таблицы, определенные в моделях.
    """
    Base.metadata.create_all(bind=engine)
