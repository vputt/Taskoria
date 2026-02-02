"""
Seed data - начальные данные для базы.

Создает начальный набор достижений.
"""
from sqlalchemy.orm import Session
from app.models.achievement import Achievement


# Список достижений для игры
ACHIEVEMENTS_DATA = [
    # Достижения за задачи
    {
        "code": "first_task",
        "name": "Первые шаги",
        "description": "Создайте свою первую задачу",
        "xp_reward": 10,
        "coins_reward": 5,
        "icon_name": "star"
    },
    {
        "code": "task_master_10",
        "name": "Новичок",
        "description": "Выполните 10 задач",
        "xp_reward": 50,
        "coins_reward": 25,
        "icon_name": "trophy_bronze"
    },
    {
        "code": "task_master_50",
        "name": "Опытный",
        "description": "Выполните 50 задач",
        "xp_reward": 150,
        "coins_reward": 75,
        "icon_name": "trophy_silver"
    },
    {
        "code": "task_master_100",
        "name": "Мастер задач",
        "description": "Выполните 100 задач",
        "xp_reward": 300,
        "coins_reward": 150,
        "icon_name": "trophy_gold"
    },
    
    # Достижения за streak
    {
        "code": "streak_3",
        "name": "Хорошее начало",
        "description": "Выполняйте задачи 3 дня подряд",
        "xp_reward": 30,
        "coins_reward": 15,
        "icon_name": "fire"
    },
    {
        "code": "streak_7",
        "name": "Неделя успеха",
        "description": "Выполняйте задачи 7 дней подряд",
        "xp_reward": 70,
        "coins_reward": 35,
        "icon_name": "fire_strong"
    },
    {
        "code": "streak_30",
        "name": "Месячный марафон",
        "description": "Выполняйте задачи 30 дней подряд",
        "xp_reward": 300,
        "coins_reward": 150,
        "icon_name": "fire_epic"
    },
    
    # Достижения за уровни
    {
        "code": "level_5",
        "name": "Растущий талант",
        "description": "Достигните 5 уровня",
        "xp_reward": 50,
        "coins_reward": 25,
        "icon_name": "level_5"
    },
    {
        "code": "level_10",
        "name": "Профессионал",
        "description": "Достигните 10 уровня",
        "xp_reward": 100,
        "coins_reward": 50,
        "icon_name": "level_10"
    },
    {
        "code": "level_20",
        "name": "Эксперт",
        "description": "Достигните 20 уровня",
        "xp_reward": 200,
        "coins_reward": 100,
        "icon_name": "level_20"
    },
    
    # Достижения за город
    {
        "code": "first_building",
        "name": "Архитектор",
        "description": "Постройте первое здание",
        "xp_reward": 30,
        "coins_reward": 0,
        "icon_name": "building"
    },
    {
        "code": "city_builder",
        "name": "Градостроитель",
        "description": "Постройте 10 зданий",
        "xp_reward": 100,
        "coins_reward": 50,
        "icon_name": "city"
    },
    
    # Достижения за категории
    {
        "code": "study_master",
        "name": "Отличник",
        "description": "Выполните 20 задач категории 'Учеба'",
        "xp_reward": 75,
        "coins_reward": 40,
        "icon_name": "book"
    },
    {
        "code": "work_master",
        "name": "Трудоголик",
        "description": "Выполните 20 задач категории 'Работа'",
        "xp_reward": 75,
        "coins_reward": 40,
        "icon_name": "briefcase"
    },
    {
        "code": "health_master",
        "name": "Здоровяк",
        "description": "Выполните 20 задач категории 'Здоровье'",
        "xp_reward": 75,
        "coins_reward": 40,
        "icon_name": "heart"
    }
]


def seed_achievements(db: Session) -> None:
    """
    Создает начальные достижения в базе данных.
    
    Args:
        db: Сессия базы данных
    """
    print("Seeding achievements...")
    
    # Проверяем, есть ли уже достижения
    existing_count = db.query(Achievement).count()
    
    if existing_count > 0:
        print(f"Achievements already exist ({existing_count} found). Skipping...")
        return
    
    # Создаем достижения
    for achievement_data in ACHIEVEMENTS_DATA:
        achievement = Achievement(**achievement_data)
        db.add(achievement)
    
    db.commit()
    print(f"Created {len(ACHIEVEMENTS_DATA)} achievements")


def seed_all(db: Session) -> None:
    """
    Создает все начальные данные.
    
    Args:
        db: Сессия базы данных
    """
    print("Starting database seeding...")
    seed_achievements(db)
    print("Database seeding completed!")


if __name__ == "__main__":
    from app.database import SessionLocal
    
    db = SessionLocal()
    try:
        seed_all(db)
    finally:
        db.close()
