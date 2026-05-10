# Taskoria: серверная часть

Серверная часть проекта Taskoria предоставляет REST API для аутентификации, управления задачами и подзадачами, начисления XP и Coins, ведения streak-системы, прогресса виртуального города, данных профиля и магазина.

## Назначение

Backend обеспечивает:

- регистрацию и аутентификацию пользователей через JWT;
- CRUD-операции для задач и подзадач;
- автоматическое разбиение задач на подзадачи через GigaChat API;
- начисление XP и Coins за выполнение задач;
- обновление уровня пользователя и streak-системы;
- хранение прогресса виртуального города и уровней зданий;
- работу магазина декоративных объектов;
- предоставление данных профиля, достижений и статистики;
- автоматическую документацию API через Swagger.

## Технологический стек

- Python 3.11
- FastAPI
- PostgreSQL 15
- SQLAlchemy
- Alembic
- Pydantic
- GigaChat API

## Дополнительные инструменты

- JWT - механизм аутентификации API.
- Pytest - тестирование серверной части.
- Swagger/OpenAPI - автоматическая документация API.
- Docker Compose - локальный запуск backend и PostgreSQL.
- Pytest

## Структура

```text
backend/
|-- app/
|   |-- api/            # роутеры FastAPI
|   |-- models/         # модели SQLAlchemy
|   |-- schemas/        # схемы Pydantic
|   |-- repositories/   # слой доступа к данным
|   |-- services/       # бизнес-логика
|   |-- factories/      # логика создания зданий
|   |-- builders/       # вспомогательная сборка города
|   |-- strategies/     # стратегии AI-провайдера
|   `-- main.py         # FastAPI-приложение
|-- alembic/            # миграции базы данных
|-- tests/              # тесты Pytest
|-- requirements.txt
`-- .env.example
```

## Установка

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
```

Перед запуском нужно отредактировать `.env` под локальное окружение.

## Переменные окружения

Безопасные примеры значений находятся в `.env.example`.

Основные переменные:

- `DATABASE_URL` - строка подключения SQLAlchemy к базе данных.
- `SECRET_KEY` - секрет для подписи JWT.
- `ACCESS_TOKEN_EXPIRE_MINUTES` - время жизни access token.
- `DEBUG` - режим разработки и отладки.
- `GIGACHAT_AUTHORIZATION_KEY` - ключ для интеграции с GigaChat API.
- `GIGACHAT_API_URL` - адрес GigaChat API.
- `GIGACHAT_OAUTH_URL` - адрес GigaChat OAuth.
- `GIGACHAT_SCOPE` - scope GigaChat.
- `REDIS_URL` - адрес Redis, если используется cache.

## База данных

Применить миграции:

```powershell
alembic upgrade head
```

Создать новую миграцию после изменения моделей:

```powershell
alembic revision --autogenerate -m "message"
```

## Запуск

```powershell
python -m uvicorn app.main:app --reload
```

Адрес по умолчанию:

```text
http://127.0.0.1:8000
```

Swagger UI:

```text
http://127.0.0.1:8000/api/docs
```

Health check:

```text
GET /health
```

## Запуск через Docker

Из корня проекта:

```powershell
docker compose up --build
```

Перед запуском должен быть открыт Docker Desktop. Ошибка про `dockerDesktopLinuxEngine` означает, что Docker Desktop или Linux engine не запущен.

Команда поднимает два контейнера:

- `taskoria_db` - PostgreSQL;
- `taskoria_backend` - FastAPI API.

После запуска доступны:

```text
http://127.0.0.1:8000/health
http://127.0.0.1:8000/api/docs
```

Для Android-эмулятора указывайте `API_BASE_URL=http://10.0.2.2:8000`.

Для физического телефона используйте один из вариантов:

- телефон и компьютер в одной Wi-Fi сети: `API_BASE_URL=http://<PC_LOCAL_IP>:8000`;
- телефон подключен по USB: сначала `adb reverse tcp:8000 tcp:8000`, затем `API_BASE_URL=http://127.0.0.1:8000`.

## Основные API

Аутентификация:

- `POST /api/auth/register`
- `POST /api/auth/login`

Пользователь:

- `GET /api/users/me`

Задачи:

- `GET /api/tasks`
- `POST /api/tasks`
- `GET /api/tasks/{task_id}`
- `PATCH /api/tasks/{task_id}`
- `DELETE /api/tasks/{task_id}`
- `POST /api/tasks/{task_id}/complete`
- `POST /api/tasks/{task_id}/split`

Подзадачи:

- `GET /api/tasks/{task_id}/subtasks`
- `POST /api/tasks/{task_id}/subtasks`
- `PATCH /api/tasks/{task_id}/subtasks/{subtask_id}`
- `POST /api/tasks/{task_id}/subtasks/{subtask_id}/start`
- `POST /api/tasks/{task_id}/subtasks/{subtask_id}/complete`
- `DELETE /api/tasks/{task_id}/subtasks/{subtask_id}`

Город:

- `GET /api/city`
- `POST /api/city/buildings`
- `PATCH /api/city/buildings/{building_id}/upgrade`

Магазин:

- `GET /api/shop`
- `POST /api/shop/items/{item_id}/purchase`
- `PATCH /api/shop/items/{item_id}/placement`

## Тесты

```powershell
pytest
```

Текущие тесты покрывают завершение задач, разбиение задач на подзадачи и логику прогресса города.
