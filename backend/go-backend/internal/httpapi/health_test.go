package httpapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealth(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/health", nil)
	recorder := httptest.NewRecorder()

	HealthHandler(recorder, request)

	result := recorder.Result()
	defer result.Body.Close()

	if result.StatusCode != http.StatusOK {
		t.Fatalf("expected status 200, got %d", result.StatusCode)
	}

	if result.Header.Get("Content-Type") != "application/json" {
		t.Fatalf("expected content-type json, got %s", result.Header.Get("Content-Type"))
	}

	var body Health

	err := json.NewDecoder(result.Body).Decode(&body)
	if err != nil {
		t.Fatalf("failed to decode response body: %v", err)
	}

	if body.Status != "healthy" {
		t.Fatalf("expected status %q, got %q", "healthy", body.Status)
	}

	if body.Service != "Taskoria API" {
		t.Fatalf("expected service %q, got %q", "Taskoria API", body.Service)
	}
}
