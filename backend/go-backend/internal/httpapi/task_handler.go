package httpapi

import (
	"net/http"
	"taskoria-go/internal/domain"
	"taskoria-go/internal/service"
)

// Цель этого файла:
// - принять HTTP-запрос;
// - прочитать JSON/body/path-параметры;
// - собрать input для service.TaskService;
// - вызвать нужный метод сервиса;
// - вернуть JSON-ответ или JSON-ошибку.

type TaskHandler struct {
	tasks *service.TaskService
}

func NewTaskHandler(tasks *service.TaskService) *TaskHandler {
	return &TaskHandler{
		tasks: tasks,
	}
}

func (h *TaskHandler) CreateTask(w http.ResponseWriter, r *http.Request) (*domain.Task, error) {
	var body createTaskRequest
	if err := readJSON(r, body); err != nil {
		writeError(w, http.StatusBadRequest, "error read request")
		return nil, err
	}

	userID := int64(1)

	requset := service.CreateTaskInput{
		Title:       body.Title,
		Description: body.Description,
		Category:    body.Category,
		Priority:    body.Priority,
		Difficulty:  body.Difficulty,
		Deadline:    body.Deadline,
	}

	if task, err := h.tasks.CreateTask(userID, requset); err != nil {
		writeError(w, http.StatusBadRequest, "error create task")
		return nil, err
	} else {
		return task, nil
	}
}

func (h *TaskHandler) ListTasks()

//
// Шаг 4:
// После CreateTask добавь ListTasks.
//
// Endpoint:
//   GET /tasks
//
// Шаг 5:
// Потом добавь:
//   GET    /tasks/{id}
//   PATCH  /tasks/{id}
//   DELETE /tasks/{id}
//   POST   /tasks/{id}/complete
//
// Для taskID сначала можно использовать strconv.ParseInt.
// Позже, когда появится auth, userID будет доставаться из request context.
