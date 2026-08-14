# Задание 03: доменная модель Task

Цель: перенести первую настоящую бизнес-сущность из Python backend в Go.

Источник правды в Python:

- `app/models/task.py`

Go-файлы для этого этапа:

- `internal/domain/task.go`
- `internal/domain/task_test.go`

Важное правило: этот этап не про HTTP и не про базу данных. В `domain` не импортируем `net/http`, `encoding/json`, SQL-пакеты, repositories, services или handlers.

## Что такое domain-слой

Domain-слой отвечает на вопрос:

```text
Что такое задача, какие у неё состояния и что задача умеет делать сама?
```

Он не отвечает на вопросы:

```text
Как принять HTTP-запрос?
Как сохранить задачу в PostgreSQL?
Как вернуть JSON?
Как проверить JWT пользователя?
```

Это будут другие слои.

## Что реализовать

В `internal/domain/task.go` нужно реализовать Go-эквивалент Python-модели `Task`:

- `TaskCategory`
- `TaskPriority`
- `TaskStatus`
- `TaskDifficulty`
- `Task`
- `Task.Start()`
- `Task.Complete()`
- `Task.Cancel()`

Для enum-подобных значений используй строковые типы.

Форма примерно такая, но это не полная реализация:

```go
type TaskStatus string

const (
    // TODO(student): добавь статусы задачи здесь.
)
```

В `Task` добавь только поля, которые относятся к самой бизнес-сущности:

- `ID`
- `UserID`
- `Title`
- `Description`
- `Category`
- `Priority`
- `Difficulty`
- `Status`
- `XPReward`
- `CoinsReward`
- `Deadline`
- `CreatedAt`
- `CompletedAt`
- `UpdatedAt`

Для дат используй `time.Time` или `*time.Time`. Если значение может отсутствовать, например `Deadline` или `CompletedAt`, лучше использовать `*time.Time`.

## Поведение из Python

Из `app/models/task.py` переносим только поведение самой задачи:

```text
start:
  если задача active -> статус становится in_progress
  иначе -> статус не меняется

complete:
  статус становится completed
  completed_at заполняется текущим временем

cancel:
  статус становится cancelled
```

Пока не добавляй service-правила. На этом этапе не проверяем владельца задачи, награды, streak, AI, subtasks и сохранение в БД.

## Какие тесты написать

В `internal/domain/task_test.go` напиши unit-тесты чистой доменной логики.

Обязательные тесты:

```text
TestTaskStart_ActiveTask
TestTaskStart_NonActiveTask
TestTaskComplete
TestTaskCancel
```

Что проверить:

- `Start` переводит `active` в `in_progress`.
- `Start` не меняет `completed`, `cancelled` и уже `in_progress`.
- `Complete` переводит задачу в `completed`.
- `Complete` заполняет `CompletedAt`.
- `Cancel` переводит задачу в `cancelled`.

В этих тестах не нужны `httptest`, `http.Request`, JSON, router, database или mock-репозитории.

## Рекомендуемый порядок

1. Определи строковые типы и константы.
2. Определи структуру `Task`.
3. Реализуй `Start`.
4. Напиши `TestTaskStart_ActiveTask`.
5. Реализуй `Cancel`.
6. Напиши `TestTaskCancel`.
7. Реализуй `Complete`.
8. Напиши `TestTaskComplete`.
9. Добавь тест на `Start` для неактивных статусов.

## Как проверить

Из папки `go-backend`:

```powershell
gofmt -w .
go test -v ./...
go vet ./...
```

## Этап готов, когда

- `go test -v ./...` проходит.
- `go vet ./...` проходит.
- Ты можешь объяснить, почему этот код лежит в `domain`, а не в `httpapi`.
- Методы `Task` ничего не знают про HTTP, JSON, repositories, services, SQL или PostgreSQL.

## Какую архитектуру мы здесь закладываем

Мы переносим backend не механически файл-в-файл, а слоями.

В Python `Task` одновременно является SQLAlchemy-моделью и содержит немного бизнес-логики:

```text
Task.complete()
Task.start()
Task.cancel()
```

В Go мы сознательно отделяем чистую доменную сущность от будущей PostgreSQL-реализации. Это более аккуратно для реального backend:

```text
domain.Task              -> бизнес-смысл задачи
storage/postgres         -> как эта задача хранится в БД
httpapi                  -> как задача приходит/уходит через JSON API
service                  -> сценарии приложения вокруг задачи
```

На этом этапе мы используем:

- Domain Entity: `Task` хранит состояние и умеет менять своё состояние.
- Часть идеи DDD Aggregate Root: позже `Task` станет корнем для операций с subtasks.
- Encapsulation: вместо прямого изменения статуса снаружи используем методы `Start`, `Complete`, `Cancel`.

Что мы пока не используем:

- Repository Pattern: появится на этапе service/storage.
- Service Layer: появится после domain-моделей.
- Factory/Builder/Strategy/Observer: они есть в Python backend, но для `Task.Start()` и `Task.Complete()` сейчас не нужны.

Это и есть нормальная архитектура: не тащить паттерны туда, где они не помогают.
