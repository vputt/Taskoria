# План переписывания Taskoria backend с Python на Go

Этот файл - рабочая карта проекта. Мы не переписываем backend "по папкам", потому что так легко получить много пустой архитектуры и мало понимания. Мы идем вертикальными срезами: берем один реальный сценарий из Python backend, переносим его в Go через все нужные слои, покрываем тестами, делаем ревью, потом идем дальше.

Правило работы:

1. Codex объясняет слой, дает задание, подсказки и критерии готовности.
2. Ты сама пишешь код.
3. Codex делает ревью, помогает исправить ошибки и только потом мы двигаемся дальше.

## Источник правды: текущий Python backend

Главные Python-файлы, на которые опираемся:

- `app/main.py` - создание FastAPI app, health, CORS, startup, подключение API router.
- `app/api/__init__.py` - общий API router и префиксы.
- `app/api/auth.py` - register/login.
- `app/api/users.py` - профиль текущего пользователя.
- `app/api/tasks.py` - CRUD задач, complete, split через AI.
- `app/api/subtasks.py` - CRUD подзадач, start/complete.
- `app/api/city.py` - город, покупка/апгрейд зданий.
- `app/api/shop.py` - магазин и размещение предметов.
- `app/api/deps.py` - DI через FastAPI `Depends`.
- `app/services/*` - application service layer.
- `app/repositories/*` - Repository Pattern.
- `app/models/*` - domain/data models.
- `app/schemas/*` - request/response DTO.
- `app/core/event_bus.py` - Observer/Event Bus.
- `app/strategies/ai_strategy.py` - Strategy для AI.
- `app/templates/reward_calculator.py` - Template Method для наград.
- `app/factories/building_factory.py` - Factory для зданий.
- `app/builders/city_builder.py` - Builder для ответа города.
- `app/states/streak_state.py` - State для streak.

## Целевая Go-структура

Структуру добавляем постепенно, когда появляется реальный код для слоя.

```text
go-backend/
  cmd/api/                     # запуск приложения
  internal/httpapi/             # router, handlers, middleware, HTTP helpers
  internal/domain/              # чистые domain entities и value objects
  internal/service/             # application services / use cases
  internal/storage/postgres/    # PostgreSQL repositories
  internal/events/              # EventBus / Observer
  internal/ai/                  # AI provider Strategy
  internal/config/              # config/env
  internal/testutil/            # общие test helpers
```

Важно: в Go интерфейсы чаще кладем рядом с тем кодом, который их использует. Например, `TaskService` может принимать `TaskRepository` interface, а PostgreSQL-реализация будет жить отдельно в `internal/storage/postgres`.

## Как Python-паттерны ложатся на Go

| Python backend | Go backend | Зачем |
| --- | --- | --- |
| `APIRouter`, decorators | `http.ServeMux`, `NewRouter()` | routing: method + path -> handler |
| FastAPI `Depends` | явные конструкторы `NewService(...)` | понятный DI без магии |
| Pydantic schemas | request/response structs | JSON contract API |
| SQLAlchemy models | domain structs + storage mapping | отделяем бизнес-логику от БД |
| Repository Pattern | repository interfaces + implementations | service не знает, где лежат данные |
| Service Layer | structs with methods | бизнес-сценарии приложения |
| EventBus / Observer | `events.Bus` | слабая связность side effects |
| Strategy | Go interface, например `AIProvider` | можно заменить GigaChat на mock |
| Template Method | interface/composition for reward calculators | алгоритм наград без наследования |
| Factory | constructor/factory functions | создание building/shop objects |
| Builder | assembler/builder for city response | собрать сложный ответ из частей |
| State | `StreakManager` + state/policy types | управление streak-переходами |
| Facade | простой сервис поверх сложных зависимостей | скрыть детали AI/reward flows |

## Этап 01. HTTP foundation: health endpoint

Python-источник:

- `app/main.py`: `GET /health`

Go-файлы:

- `cmd/api/main.go`
- `internal/httpapi/health.go`
- `internal/httpapi/health_test.go`
- `internal/httpapi/router.go`
- `internal/httpapi/router_test.go`

Что должно быть понятно:

- что такое `http.Handler`;
- что такое `http.ResponseWriter`;
- что такое `*http.Request`;
- что такое `http.ServeMux`;
- почему handler-test и router-test проверяют разные уровни.

Статус: почти готово.

Что еще поправить перед следующим этапом:

- убрать старый закомментированный код из `cmd/api/main.go`;
- в тесте использовать `"Content-Type"`, а не `"Content-type"`;
- добавить в `router_test.go` проверки `GET /health -> 200` и `GET /unknown -> 404`.

Команда проверки:

```powershell
go test -v ./...
```

## Этап 02. Общие HTTP helpers

Python-источник:

- FastAPI автоматически делает JSON response, JSON parsing и часть ошибок.

Go-цель:

- руками написать маленькие helpers, чтобы каждый handler не копировал одно и то же.

Будущие файлы:

- `internal/httpapi/json.go`
- `internal/httpapi/errors.go`
- `internal/httpapi/json_test.go`

Что реализовать:

- `writeJSON(w, status, data)`;
- `readJSON(r, dst)`;
- единый формат ошибки, например `{"error":"..."}`;
- корректный `Content-Type`;
- `400 Bad Request` при битом JSON.

Паттерн:

- не классический GoF, а инфраструктурный helper layer.

Критерий готовности:

- health handler использует `writeJSON`;
- есть тест на успешный JSON response;
- есть тест на ошибку декодирования плохого JSON.

## Этап 03. Domain basics: User, Task, Subtask

Python-источник:

- `app/models/user.py`
- `app/models/task.py`
- `app/models/subtask.py`

Go-цель:

- перенести бизнес-сущности без HTTP и без БД.

Будущие файлы:

- `internal/domain/user.go`
- `internal/domain/task.go`
- `internal/domain/subtask.go`
- `internal/domain/*_test.go`

Что реализовать:

- enums/status values для task/subtask;
- `Task.Complete()`;
- `Task.Start()`;
- `Task.Cancel()`;
- `Subtask.Start()`;
- `Subtask.Complete()`;
- `User.AddXP()`;
- `User.AddCoins()`;
- `User.SpendCoins()`;
- `User.CalculateLevel()`.

Паттерны:

- Domain Entity;
- Aggregate Root: `Task` как корень для subtasks.

Критерий готовности:

- unit-тесты доменной логики без HTTP, БД и моков.

## Этап 04. Task service + in-memory repository

Python-источник:

- `app/services/task_service.py`
- `app/repositories/task_repository.py`
- `app/repositories/subtask_repository.py`

Go-цель:

- впервые собрать цепочку `handler -> service -> repository`, но пока без PostgreSQL.

Будущие файлы:

- `internal/service/task_service.go`
- `internal/service/task_service_test.go`
- `internal/storage/memory/task_repository.go`

Что реализовать:

- `ListTasks(userID, skip, limit)`;
- `CreateTask(userID, input)`;
- `GetTask(userID, taskID)`;
- `UpdateTask(userID, taskID, input)`;
- `DeleteTask(userID, taskID)`;
- нормальные ошибки: not found, forbidden, validation.

Паттерны:

- Service Layer;
- Repository Pattern;
- Dependency Injection через конструктор.

Критерий готовности:

- сервис тестируется через fake/in-memory repository;
- HTTP еще можно не трогать или подключить только `GET /tasks`.

## Этап 05. Tasks HTTP API

Python-источник:

- `app/api/tasks.py`
- `app/schemas/task.py`

Go-цель:

- перенести первый реальный API-модуль.

Endpoint'ы:

- `GET /api/v1/tasks`
- `POST /api/v1/tasks`
- `GET /api/v1/tasks/{task_id}`
- `PATCH /api/v1/tasks/{task_id}`
- `DELETE /api/v1/tasks/{task_id}`

Пока без:

- JWT;
- AI split;
- PostgreSQL.

Будущие файлы:

- `internal/httpapi/tasks.go`
- `internal/httpapi/task_dto.go`
- `internal/httpapi/tasks_test.go`

Паттерны:

- Controller/Handler layer;
- DTO mapping;
- Service Layer.

Критерий готовности:

- router-test проверяет маршруты;
- handler-test проверяет JSON, статусы и ошибки;
- сервисные ошибки переводятся в HTTP-коды.

## Этап 06. Config + application wiring

Python-источник:

- `app/config.py`
- `app/api/deps.py`
- `app/core/container.py`

Go-цель:

- заменить FastAPI `Depends` явной сборкой зависимостей.

Будущие файлы:

- `internal/config/config.go`
- `internal/app/app.go` или явная сборка в `cmd/api/main.go`

Что реализовать:

- чтение env;
- порт сервера;
- секрет JWT;
- DSN базы;
- создание services/repositories в одном месте.

Паттерны:

- Dependency Injection;
- Composition Root.

Критерий готовности:

- handler'ы не создают себе repositories сами;
- зависимости приходят через конструкторы.

## Этап 07. Auth and current user

Python-источник:

- `app/api/auth.py`
- `app/api/users.py`
- `app/services/auth_service.py`
- `app/schemas/user.py`

Go-цель:

- register/login/me и middleware текущего пользователя.

Endpoint'ы:

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/users/me`

Что важно:

- в Python пароль временно сравнивается как plain text;
- в Go сразу делаем нормальное хеширование пароля;
- JWT проверяется в middleware/dependency layer.

Паттерны:

- Service Layer;
- Repository;
- Middleware;
- DI.

Критерий готовности:

- register создает пользователя;
- login возвращает access token;
- `/users/me` без токена возвращает `401`;
- `/users/me` с токеном возвращает профиль.

## Этап 08. PostgreSQL repositories

Python-источник:

- `app/database.py`
- `app/repositories/*`
- `app/models/*`

Go-цель:

- заменить in-memory storage на PostgreSQL.

Будущие файлы:

- `internal/storage/postgres/db.go`
- `internal/storage/postgres/user_repository.go`
- `internal/storage/postgres/task_repository.go`
- `internal/storage/postgres/subtask_repository.go`

Техническое решение:

- использовать `database/sql` + pgx driver или чистый `pgx`;
- миграции подключить отдельным шагом.

Паттерны:

- Repository implementation;
- Adapter: service видит interface, а не SQL.

Критерий готовности:

- сервисные тесты все еще могут идти на fake repo;
- repository integration tests идут отдельно;
- API работает с реальной БД.

## Этап 09. Subtasks API

Python-источник:

- `app/api/subtasks.py`
- `app/services/task_service.py`
- `app/repositories/subtask_repository.py`

Endpoint'ы:

- `GET /api/v1/tasks/{task_id}/subtasks`
- `POST /api/v1/tasks/{task_id}/subtasks`
- `PATCH /api/v1/tasks/{task_id}/subtasks/{subtask_id}`
- `POST /api/v1/tasks/{task_id}/subtasks/{subtask_id}/start`
- `POST /api/v1/tasks/{task_id}/subtasks/{subtask_id}/complete`
- `DELETE /api/v1/tasks/{task_id}/subtasks/{subtask_id}`

Паттерны:

- Aggregate Root: subtask принадлежит task;
- Repository;
- Service Layer.

Критерий готовности:

- нельзя менять чужие subtasks;
- нельзя менять subtask не из указанной task;
- start/complete покрыты unit-тестами.

## Этап 10. Rewards, streak and events

Python-источник:

- `app/services/reward_service.py`
- `app/templates/reward_calculator.py`
- `app/states/streak_state.py`
- `app/core/event_bus.py`
- `app/core/observers.py`

Go-цель:

- перенести награды, уровни, streak и события после complete task.

Паттерны:

- Template Method через interface/composition для reward calculator;
- State или Policy для streak;
- Observer/EventBus для side effects;
- Domain Entity: `User.AddXP`, `User.SpendCoins`.

Где могут появиться goroutines/channels:

- EventBus можно сначала сделать синхронным;
- потом можно добавить async-обработку событий через channel и worker;
- это хорошее место для каналов, но не первый этап.

Критерий готовности:

- `POST /tasks/{id}/complete` меняет статус задачи;
- начисляет XP/coins;
- обновляет streak;
- публикует события;
- все критичные ветки покрыты тестами.

## Этап 11. AI Strategy

Python-источник:

- `app/services/ai_service.py`
- `app/strategies/ai_strategy.py`
- `app/utils/gigachat_client.py`

Go-цель:

- сделать интерфейс AI-провайдера и mock-реализацию для тестов.

Endpoint'ы:

- `POST /api/v1/tasks/{task_id}/split`

Паттерны:

- Strategy: `AIProvider`;
- Facade: `AIService`;
- Adapter: GigaChat client.

Где полезны goroutines:

- не для обычного handler'а;
- полезны для timeout/cancel через `context.Context`;
- потенциально для фоновой AI-задачи, если split станет долгим.

Критерий готовности:

- тесты сервиса используют mock AI;
- GigaChat можно заменить без изменения `TaskService`;
- ошибки AI не ломают весь backend.

## Этап 12. City and shop

Python-источник:

- `app/api/city.py`
- `app/api/shop.py`
- `app/services/city_service.py`
- `app/services/shop_service.py`
- `app/factories/building_factory.py`
- `app/builders/city_builder.py`
- `app/core/city_progression_policy.py`

Endpoint'ы:

- `GET /api/v1/city`
- `POST /api/v1/city/buildings`
- `PATCH /api/v1/city/buildings/{building_id}/upgrade`
- `GET /api/v1/shop`
- `POST /api/v1/shop/items/{item_id}/purchase`
- `PATCH /api/v1/shop/items/{item_id}/placement`

Паттерны:

- Factory для создания building;
- Builder/Assembler для city response;
- Policy для правил прогрессии города;
- Service Layer + Repository.

Критерий готовности:

- нельзя купить здание без coins;
- нельзя поставить два здания в одну клетку;
- upgrade считает цену как в Python;
- city response совпадает по смыслу с Python API.

## Этап 13. Middleware and production behavior

Python-источник:

- `app/main.py`: CORS, global exception handler, startup/shutdown.

Go-цель:

- привести сервер к нормальному backend-виду.

Что реализовать:

- logging middleware;
- recover middleware;
- CORS middleware;
- auth middleware;
- request timeout;
- graceful shutdown;
- единый формат ошибок.

Паттерны:

- Middleware chain;
- Decorator-like wrapping for handlers.

Где полезны goroutines/channels:

- graceful shutdown;
- background workers;
- async EventBus;
- periodic jobs.

Критерий готовности:

- сервер корректно останавливается;
- panic не роняет процесс без JSON-ответа;
- защищенные endpoint'ы требуют auth.

## Этап 14. Финальная сверка с Python backend

Цель:

- проверить, что Go backend покрывает реальные сценарии Python backend.

Что сверяем:

- все endpoint'ы;
- request/response JSON;
- статусы HTTP;
- бизнес-правила;
- ошибки;
- auth;
- работа с БД;
- side effects: rewards, streak, events, city/shop.

Критерий готовности:

- есть README с запуском;
- есть env example;
- `go test ./...` проходит;
- основные API-сценарии проверены integration/e2e тестами;
- старый Python backend можно использовать как reference, но Go backend уже самостоятельный.

## Ближайший следующий шаг

Следующий рабочий шаг после текущего состояния:

1. Дочистить этап 01:
   - убрать старые комментарии из `cmd/api/main.go`;
   - поправить `Content-Type` в `health_test.go`;
   - расширить `router_test.go`: `GET /health -> 200`, `POST /health -> 405`, `GET /unknown -> 404`.
2. Затем начать этап 02:
   - создать HTTP helper для JSON response;
   - переписать `HealthHandler` на этот helper;
   - написать тесты helper'а.

После этого можно будет безопасно идти в первый настоящий бизнес-модуль: `tasks`.
