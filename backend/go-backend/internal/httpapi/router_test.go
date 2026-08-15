package httpapi

import (
	"net/http"
	"net/http/httptest"
	"taskoria-go/internal/service"
	"taskoria-go/internal/storage/memory"
	"testing"
)

func TestRouter(t *testing.T) {
	repo := memory.NewTaskRepository()
	taskService := service.NewTaskService(repo)
	taskHandler := NewTaskHandler(taskService)
	router := NewRouter(taskHandler)

	tests := []struct {
		name       string
		method     string
		path       string
		wantStatus int
	}{
		{
			name:       "GET /health returns 200",
			method:     http.MethodGet,
			path:       "/health",
			wantStatus: http.StatusOK,
		},
		{
			name:       "POST /health returns 405",
			method:     http.MethodPost,
			path:       "/health",
			wantStatus: http.StatusMethodNotAllowed,
		},
		{
			name:       "GET /unknown returns 404",
			method:     http.MethodGet,
			path:       "/unknown",
			wantStatus: http.StatusNotFound,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			request := httptest.NewRequest(tt.method, tt.path, nil)
			recorder := httptest.NewRecorder()

			router.ServeHTTP(recorder, request)

			result := recorder.Result()
			defer result.Body.Close()

			if result.StatusCode != tt.wantStatus {
				t.Fatalf("expected status %d, got %d", tt.wantStatus, result.StatusCode)
			}
		})
	}
}
