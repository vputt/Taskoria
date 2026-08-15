package httpapi

// TODO(student): Напиши тесты для HTTP handlers задач.
//
// Начни с POST /tasks.
//
// Что проверять в TestCreateTask:
// - валидный JSON возвращает 201 Created;
// - response имеет Content-Type application/json;
// - response body содержит созданную задачу;
// - title сохраняется trimmed;
// - status по умолчанию active;
// - ID проставлен.
//
// Что проверять в ошибках:
// - битый JSON -> 400;
// - пустой title -> 400;
// - невалидная category -> 400;
// - deadline в прошлом -> 400.
//
// Подсказка по сборке handler в тесте:
// - создай memory.NewTaskRepository();
// - создай service.NewTaskService(repo);
// - создай NewTaskHandler(taskService);
// - вызови нужный метод handler напрямую через httptest.
//
// Примерный набор инструментов:
// - httptest.NewRequest
// - httptest.NewRecorder
// - strings.NewReader для JSON body
// - json.NewDecoder для проверки response body
//
// Потом добавь тесты:
// - GET /tasks возвращает список;
// - PATCH /tasks/{id} обновляет только переданные поля;
// - DELETE /tasks/{id} возвращает 204;
// - POST /tasks/{id}/complete завершает задачу.
