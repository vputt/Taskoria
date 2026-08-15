package httpapi

import (
	"errors"
	"net/http"
	"strconv"

	"taskoria-go/internal/service"
)

const temporaryUserID int64 = 1

type TaskHandler struct {
	tasks *service.TaskService
}

func NewTaskHandler(tasks *service.TaskService) *TaskHandler {
	return &TaskHandler{
		tasks: tasks,
	}
}

func (h *TaskHandler) CreateTask(w http.ResponseWriter, r *http.Request) {
	var body createTaskRequest
	if err := readJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	input := body.toServiceInput()
	task, err := h.tasks.CreateTask(temporaryUserID, input)
	if err != nil {
		writeTaskServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusCreated, newTaskResponse(task))
}

func (h *TaskHandler) ListTasks(w http.ResponseWriter, r *http.Request) {
	tasks, err := h.tasks.ListTasks(temporaryUserID)
	if err != nil {
		writeTaskServiceError(w, err)
		return
	}

	response := make([]taskResponse, 0, len(tasks))
	for i := range tasks {
		response = append(response, newTaskResponse(&tasks[i]))
	}

	writeJSON(w, http.StatusOK, response)
}

func (h *TaskHandler) GetTask(w http.ResponseWriter, r *http.Request) {
	taskID, err := taskIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid task id")
		return
	}

	task, err := h.tasks.GetTask(temporaryUserID, taskID)
	if err != nil {
		writeTaskServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, newTaskResponse(task))
}

func (h *TaskHandler) UpdateTask(w http.ResponseWriter, r *http.Request) {
	taskID, err := taskIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid task id")
		return
	}

	var body updateTaskRequest
	if err := readJSON(r, &body); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	input := body.toServiceInput()
	task, err := h.tasks.UpdateTask(temporaryUserID, taskID, input)
	if err != nil {
		writeTaskServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, newTaskResponse(task))
}

func (h *TaskHandler) DeleteTask(w http.ResponseWriter, r *http.Request) {
	taskID, err := taskIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid task id")
		return
	}

	if err := h.tasks.DeleteTask(temporaryUserID, taskID); err != nil {
		writeTaskServiceError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *TaskHandler) CompleteTask(w http.ResponseWriter, r *http.Request) {
	taskID, err := taskIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid task id")
		return
	}

	task, err := h.tasks.CompleteTask(temporaryUserID, taskID)
	if err != nil {
		writeTaskServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, newTaskResponse(task))
}

func taskIDFromRequest(r *http.Request) (int64, error) {
	taskID, err := strconv.ParseInt(r.PathValue("id"), 10, 64)
	if err != nil || taskID <= 0 {
		return 0, errors.New("invalid task id")
	}

	return taskID, nil
}
