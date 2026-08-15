package httpapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"taskoria-go/internal/service"
	"taskoria-go/internal/storage/memory"
)

func TestTaskHandlerCreateTask(t *testing.T) {
	handler := newTestTaskHandler()
	request := httptest.NewRequest(
		http.MethodPost,
		"/tasks",
		strings.NewReader(`{
			"title": "  Learn Go  ",
			"description": "Finish task API",
			"category": "study",
			"priority": "high",
			"difficulty": "medium"
		}`),
	)
	recorder := httptest.NewRecorder()

	handler.CreateTask(recorder, request)

	result := recorder.Result()
	defer result.Body.Close()

	if result.StatusCode != http.StatusCreated {
		t.Fatalf("expected status %d, got %d", http.StatusCreated, result.StatusCode)
	}

	var response taskResponse
	if err := json.NewDecoder(result.Body).Decode(&response); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if response.ID == 0 {
		t.Fatal("expected task id to be set")
	}

	if response.Title != "Learn Go" {
		t.Fatalf("expected trimmed title, got %q", response.Title)
	}
}

func TestTaskHandlerCreateTaskInvalidJSON(t *testing.T) {
	handler := newTestTaskHandler()
	request := httptest.NewRequest(
		http.MethodPost,
		"/tasks",
		strings.NewReader(`{"title":`),
	)
	recorder := httptest.NewRecorder()

	handler.CreateTask(recorder, request)

	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, recorder.Code)
	}
}

func newTestTaskHandler() *TaskHandler {
	repository := memory.NewTaskRepository()
	taskService := service.NewTaskService(repository)

	return NewTaskHandler(taskService)
}
