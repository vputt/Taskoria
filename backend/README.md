# Taskoria — серверная часть (Backend)

**Taskoria** (Геймифицированное мобильное приложение для управления задачами и визуализации прогресса / Gamified Mobile Application for Task Management and Progress Visualization) — курсовой проект. Данный репозиторий содержит серверную часть приложения: REST API на FastAPI и бизнес-логику.

## Назначение

Backend обеспечивает:

- Регистрацию и аутентификацию пользователей (JWT).
- CRUD-операции с задачами и подзадачами.
- Автоматическое разбиение задачи на подзадачи и оценку наград с помощью ИИ (интеграция с GigaChat API).
- Завершение задач с начислением XP и монет, обновлением уровня и streak.
- Профиль пользователя с игровыми метриками (уровень, XP, Coins, streak, счётчики достижений и зданий).

## Технологический стек

| Компонент | Технология |
|-----------|------------|
| Язык | Python 3.11+ |
| Фреймворк | FastAPI |
| СУБД | PostgreSQL 15+ |
| ORM | SQLAlchemy |
| Миграции | Alembic |
| Валидация | Pydantic |
| Сервер | Uvicorn (ASGI) |

## Требования к окружению

- Python 3.11 или выше.
- PostgreSQL 15 или выше.
- Переменные окружения (см. раздел «Настройка»).

## Установка и запуск

### 1. Клонирование и переход в каталог

```bash
cd backend
```

### 2. Виртуальное окружение и зависимости

```bash
python -m venv venv
venv\Scripts\activate   # Windows
# source venv/bin/activate  # Linux / macOS
pip install -r requirements.txt
```

### 3. База данных

Создайте базу данных в PostgreSQL, например:

```bash
createdb taskoria_db
```

Либо через `psql`:

```sql
CREATE DATABASE taskoria_db;
```

### 4. Настройка переменных окружения

Создайте файл `.env` в корне папки `backend` (файл `.env` не должен попадать в репозиторий). Пример структуры:

```env
DATABASE_URL=postgresql://user:password@localhost:5432/taskoria_db
SECRET_KEY=your-secret-key-change-in-production
GIGACHAT_AUTHORIZATION_KEY=your-api-authorization-key
```

При необходимости укажите дополнительные параметры (URL API, OAuth и т.д.) в соответствии с конфигурацией в `app/config.py`.

### 5. Миграции

```bash
alembic upgrade head
```

### 6. Начальные данные (опционально)

Загрузка предопределённых достижений:

```bash
python -m app.utils.seed_data
```

### 7. Запуск сервера

```bash
python -m app.main
```

Либо через Uvicorn:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

После запуска:

- API: <http://localhost:8000>
- Документация Swagger: <http://localhost:8000/api/docs>
- ReDoc: <http://localhost:8000/api/redoc>
- Проверка состояния: <http://localhost:8000/health>

## Структура проекта

```
backend/
├── app/
│   ├── api/              # Эндпоинты HTTP (auth, tasks, users, subtasks)
│   ├── core/             # Ядро (контейнер зависимостей, шина событий)
│   ├── models/           # Модели SQLAlchemy (User, Task, Subtask, Achievement, Building, Statistics)
│   ├── schemas/          # Схемы Pydantic для запросов и ответов
│   ├── repositories/     # Слой доступа к данным (Repository Pattern)
│   ├── services/        # Бизнес-логика (задачи, награды, аутентификация, ИИ-сервис)
│   ├── strategies/     # ИИ-стратегии: разбиение задач, оценка сложности и наград (Strategy Pattern)
│   ├── templates/       # Шаблоны расчёта наград (Template Method)
│   ├── states/          # Управление состоянием streak (State Pattern)
│   ├── factories/       # Создание зданий (Factory Pattern)
│   ├── builders/        # Построение города (Builder Pattern)
│   ├── utils/           # Утилиты (клиент внешнего API, начальные данные)
│   ├── config.py        # Конфигурация приложения
│   ├── database.py      # Подключение к БД
│   └── main.py          # Точка входа FastAPI
├── alembic/             # Миграции БД
├── requirements.txt
├── .gitignore
└── README.md
```

## API (кратко)

| Метод | Путь | Описание |
|-------|------|----------|
| POST | /api/auth/register | Регистрация |
| POST | /api/auth/login | Вход (JWT) |
| GET | /api/tasks | Список задач (с пагинацией: skip, limit) |
| POST | /api/tasks | Создание задачи |
| GET | /api/tasks/{id} | Задача с подзадачами |
| PATCH | /api/tasks/{id} | Обновление задачи |
| DELETE | /api/tasks/{id} | Удаление задачи |
| POST | /api/tasks/{id}/complete | Завершение задачи (награды, streak) |
| POST | /api/tasks/{id}/split | Разбиение задачи на подзадачи с помощью ИИ |
| GET | /api/tasks/{id}/subtasks | Список подзадач |
| POST | /api/tasks/{id}/subtasks | Создание подзадачи |
| PATCH | /api/tasks/{id}/subtasks/{sid} | Обновление подзадачи |
| DELETE | /api/tasks/{id}/subtasks/{sid} | Удаление подзадачи |
| POST | /api/tasks/{id}/subtasks/{sid}/complete | Завершение подзадачи |
| POST | /api/tasks/{id}/subtasks/{sid}/start | Начало выполнения подзадачи |
| GET | /api/users/me | Профиль текущего пользователя |
| GET | /health | Проверка состояния сервера |

## Паттерны проектирования (используемые в проекте)

- **Singleton** — конфигурация, подключение к БД, шина событий.
- **Dependency Injection** — внедрение зависимостей через FastAPI Depends.
- **Repository** — абстракция доступа к данным.
- **Strategy** — выбор ИИ-провайдера (разбиение задач, оценка сложности и наград; например, GigaChat).
- **Template Method** — расчёт наград с переопределяемыми шагами.
- **State** — управление состоянием streak.
- **Observer** — шина событий (достижения, уровни).
- **Factory** — создание зданий разных типов.
- **Builder** — построение сложного объекта города.
- **Facade** — упрощение сложных операций (завершение задачи, вызов сервиса разбиения).
- **DDD** — доменные сущности и агрегаты (Task как Aggregate Root с подзадачами).
