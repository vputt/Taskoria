"""
Базовый репозиторий с общей логикой CRUD операций.

Паттерн: Repository
Обоснование: Абстрагирует доступ к данным, упрощает тестирование
(можно использовать mock-репозитории), обеспечивает единообразный интерфейс работы с БД.
"""
from typing import Generic, TypeVar, Type, Optional, List
from sqlalchemy.orm import Session
from app.database import Base

ModelType = TypeVar("ModelType", bound=Base)


class BaseRepository(Generic[ModelType]):
    """
    Базовый репозиторий (Repository Pattern).
    
    Применяемый паттерн: Repository Pattern
    - Абстрагирует персистентность данных
    - Предоставляет единообразный интерфейс для CRUD операций
    - Упрощает тестирование (легко создать mock-репозитории)
    
    Преимущества:
    - Разделение бизнес-логики и доступа к данным
    - Возможность замены источника данных без изменения бизнес-логики
    - Упрощенное тестирование
    
    Example:
        class UserRepository(BaseRepository[User]):
            def __init__(self, db: Session):
                super().__init__(User, db)
            
            def get_by_email(self, email: str) -> Optional[User]:
                return self.db.query(self.model).filter(
                    self.model.email == email
                ).first()
    """
    
    def __init__(self, model: Type[ModelType], db: Session):
        """
        Инициализация репозитория.
        
        Args:
            model: Класс модели SQLAlchemy
            db: Сессия базы данных (Dependency Injection)
        """
        self.model = model
        self.db = db
    
    def get(self, id: int) -> Optional[ModelType]:
        """
        Получает объект по ID.
        
        Args:
            id: ID объекта
            
        Returns:
            Объект или None
        """
        return self.db.query(self.model).filter(self.model.id == id).first()
    
    def get_all(self, skip: int = 0, limit: int = 100) -> List[ModelType]:
        """
        Получает список объектов.
        
        Args:
            skip: Количество пропускаемых записей
            limit: Максимальное количество записей
            
        Returns:
            Список объектов
        """
        return self.db.query(self.model).offset(skip).limit(limit).all()
    
    def create(self, obj_in: dict) -> ModelType:
        """
        Создает новый объект.
        
        Args:
            obj_in: Словарь с данными объекта
            
        Returns:
            Созданный объект
        """
        db_obj = self.model(**obj_in)
        self.db.add(db_obj)
        self.db.commit()
        self.db.refresh(db_obj)
        return db_obj
    
    def update(self, db_obj: ModelType, obj_in: dict) -> ModelType:
        """
        Обновляет существующий объект.
        
        Args:
            db_obj: Объект для обновления
            obj_in: Словарь с новыми данными
            
        Returns:
            Обновленный объект
        """
        for field, value in obj_in.items():
            if hasattr(db_obj, field) and value is not None:
                setattr(db_obj, field, value)
        
        self.db.commit()
        self.db.refresh(db_obj)
        return db_obj
    
    def delete(self, id: int) -> bool:
        """
        Удаляет объект по ID.
        
        Args:
            id: ID объекта
            
        Returns:
            True если объект был удален, False если не найден
        """
        obj = self.get(id)
        if obj:
            self.db.delete(obj)
            self.db.commit()
            return True
        return False
    
    def count(self) -> int:
        """
        Подсчитывает количество объектов.
        
        Returns:
            Количество объектов
        """
        return self.db.query(self.model).count()
    
    def exists(self, id: int) -> bool:
        """
        Проверяет существование объекта.
        
        Args:
            id: ID объекта
            
        Returns:
            True если объект существует, False иначе
        """
        return self.db.query(self.model).filter(self.model.id == id).count() > 0
