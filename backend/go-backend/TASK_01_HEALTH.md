# Задание 01: HTTP-сервер и health endpoint

## Цель

Самостоятельно провести первый запрос по цепочке:

`GET /health → router → handler → JSON response`.

На этом этапе не нужны service, repository, PostgreSQL, goroutines или channels.

## Что реализовать

### `internal/httpapi/health.go`

Реализовать экспортируемый health handler, который:

1. принимает `http.ResponseWriter` и `*http.Request`;
2. устанавливает `Content-Type: application/json`;
3. возвращает HTTP 200;
4. возвращает JSON с полями `status` и `service`;
5. не пишет JSON вручную конкатенацией строк.

Ожидаемые значения:

- `status`: `healthy`;
- `service`: `Taskoria API`.

Подсказки: пакеты `net/http` и `encoding/json`; функция-кодировщик должна получить значение, подходящее для JSON.

### `cmd/api/main.go`

Самостоятельно:

1. создать `http.ServeMux`;
2. зарегистрировать маршрут `GET /health`;
3. создать HTTP-сервер на порту `8080`;
4. запустить сервер;
5. обработать ошибку запуска, не игнорируя её.

Подсказки: `http.NewServeMux`, метод `HandleFunc`, структура `http.Server`. Graceful shutdown добавим отдельным следующим заданием.

### `internal/httpapi/health_test.go`

Написать тест без запуска реального сетевого порта. Проверить:

1. status code 200;
2. `Content-Type` содержит `application/json`;
3. тело является валидным JSON;
4. значения `status` и `service` совпадают с контрактом.

Подсказки: пакет `net/http/httptest`, `httptest.NewRequest`, `httptest.NewRecorder`.

## Как проверить

Из каталога `go-backend`:

```powershell
go test ./...
go run ./cmd/api
```

В другом терминале:

```powershell
curl.exe -i http://localhost:8080/health
```

## Критерий завершения

- сервер запускается;
- `GET /health` возвращает 200 и ожидаемый JSON;
- тест проходит;
- ты можешь объяснить назначение `ServeMux`, handler, `ResponseWriter` и `httptest.ResponseRecorder`;
- ожидаемый commit: `feat: add health endpoint`.

## Вопросы перед code review

1. Почему handler получает `ResponseWriter`, а не возвращает JSON напрямую?
2. Зачем устанавливать `Content-Type` до записи тела?
3. Почему в тесте не нужен настоящий сервер на порту 8080?
4. Что произойдёт, если JSON encoder вернёт ошибку?
5. Почему для `/health` пока не нужен service-слой?
