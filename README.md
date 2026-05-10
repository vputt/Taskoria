# Taskoria

Taskoria - геймифицированное мобильное приложение для управления задачами и визуализации прогресса. Пользователь создает и выполняет повседневные задачи, получает XP и Coins, развивает виртуальный изометрический город, открывает достижения и поддерживает регулярность выполнения дел через streak-систему.

Полное название проекта: **Геймифицированное мобильное приложение для управления задачами и визуализации прогресса - Taskoria**.

## Цель проекта

Цель проекта - разработка мобильного приложения для планирования и выполнения повседневных задач с элементами геймификации и игровой прогрессии. Приложение превращает пользовательские задачи в квесты в стиле RPG, предоставляет игровые награды за выполнение дел, визуализирует развитие виртуального города и мотивирует пользователя регулярно выполнять задания.

## Состав проекта

- `productivity_city/` - мобильное приложение Flutter для Android.
- `backend/` - серверная часть на FastAPI.

## Возможности

- Регистрация, вход и выход из аккаунта.
- Создание, просмотр, редактирование, удаление и завершение задач.
- Категории задач, приоритет, сложность, дедлайн, награды в XP и Coins.
- Разбиение задач на подзадачи через backend-сервис и интеграцию с GigaChat API.
- Прогресс профиля: уровень, XP, Coins, streak и статистика выполненных задач.
- Экран виртуального города с визуализацией зданий, уровнями зданий, ратушей и декоративными объектами.
- Магазин с сохранением купленных и размещенных объектов на backend.
- Система достижений и счетчик достижений в профиле.
- Календарь, уведомления, настройки, onboarding и профиль.
- Режим локальных mock-данных и режим интеграции с backend `core_api`.

## Технологический стек

Серверная часть:

- Python 3.11
- FastAPI
- PostgreSQL 15
- SQLAlchemy
- Alembic
- Pydantic
- GigaChat API

Клиентская часть:

- Flutter 3.0+
- Dart 3.0+
- Riverpod
- GoRouter
- Dio

## Дополнительные инструменты и библиотеки

- Pytest - тестирование серверной части.
- Flutter test и Flutter analyze - проверка клиентской части.
- JWT - механизм аутентификации API.
- Swagger/OpenAPI - автоматическая документация API.
- Docker Compose - локальный запуск backend и PostgreSQL в контейнерах.

## Структура проекта

```text
.
|-- backend/              # серверная часть на FastAPI
|-- productivity_city/    # мобильное приложение Flutter
|-- docker-compose.yml    # контейнерный запуск backend и PostgreSQL
|-- README.md             # общее описание проекта
|-- .gitignore
`-- .gitattributes
```

## Быстрый запуск

### Серверная часть

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
alembic upgrade head
python -m uvicorn app.main:app --reload
```

Адрес backend по умолчанию:

```text
http://127.0.0.1:8000
```

Swagger UI:

```text
http://127.0.0.1:8000/api/docs
```

### Docker

Docker Compose поднимает PostgreSQL и backend API:

```powershell
docker compose up --build
```

Перед запуском должен быть открыт Docker Desktop. Если появляется ошибка про `dockerDesktopLinuxEngine`, значит Docker Desktop или его Linux engine не запущен.

После запуска:

```text
http://127.0.0.1:8000/health
http://127.0.0.1:8000/api/docs
```

Клиентское Android-приложение запускается отдельно через Flutter, потому что оно устанавливается на эмулятор или физическое устройство.

Если приложение запускается на Android-эмуляторе, backend из Docker доступен так:

```powershell
flutter run --dart-define=APP_DATA_MODE=core_api --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Если приложение запускается на физическом телефоне по Wi-Fi, телефон и компьютер должны быть в одной сети, а в `API_BASE_URL` нужно указать IP компьютера:

```powershell
flutter run --dart-define=APP_DATA_MODE=core_api --dart-define=API_BASE_URL=http://<PC_LOCAL_IP>:8000
```

Если телефон подключен по USB с включенной отладкой, можно пробросить порт через ADB:

```powershell
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=APP_DATA_MODE=core_api --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Клиентская часть

```powershell
cd productivity_city
flutter pub get
flutter run
```

Запуск с backend на Android-эмуляторе:

```powershell
flutter run --dart-define=APP_DATA_MODE=core_api --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Запуск с backend на физическом Android-устройстве:

```powershell
flutter run --dart-define=APP_DATA_MODE=core_api --dart-define=API_BASE_URL=http://<PC_LOCAL_IP>:8000
```

Запуск в локальном mock-режиме:

```powershell
flutter run --dart-define=USE_MOCK_DATA=true
```

## Переменные окружения

Переменные backend описаны в файле `backend/.env.example`.

Основные `dart-define` параметры клиентской части:

- `APP_DATA_MODE=core_api` - использовать FastAPI backend.
- `API_BASE_URL=http://...` - базовый адрес backend.
- `USE_MOCK_DATA=true` - использовать локальные mock-данные, если `APP_DATA_MODE` не равен `core_api`.

## Проверки

Серверная часть:

```powershell
cd backend
pytest
```

Клиентская часть:

```powershell
cd productivity_city
flutter analyze
flutter test
```

## Документация в репозитории

- [README серверной части](backend/README.md)
- [README клиентской части](productivity_city/README.md)

Учебные отчетные документы и шаблоны хранятся локально и не добавляются в GitHub-репозиторий.

## Состояние репозитория

Репозиторий подготовлен для публикации исходного кода и README. Локальные шаблоны в `temp/`, отчетные документы в `docs/`, файлы окружения, build-артефакты, виртуальные окружения, IDE-файлы и cache-файлы игнорируются.
