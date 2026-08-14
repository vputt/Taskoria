package httpapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type testRequest struct {
	Title    string `json:"title"`
	Priority string `json:"priority"`
}

func TestWriteJSON(t *testing.T) {
	recorder := httptest.NewRecorder()

	data := map[string]string{
		"message": "create",
	}

	writeJSON(recorder, http.StatusCreated, data)

	result := recorder.Result()
	defer result.Body.Close()

	if result.StatusCode != http.StatusCreated {
		t.Fatalf("expected status 201, got %d", result.StatusCode)
	}

	if result.Header.Get("Content-Type") != "application/json" {
		t.Fatalf("expected content-type json, got %s", result.Header.Get("Content-Type"))
	}

	body := make(map[string]string)

	err := json.NewDecoder(result.Body).Decode(&body)
	if err != nil {
		t.Fatalf("failed to decode response body: %v", err)
	}

	if body["message"] != "create" {
		t.Fatalf("expected message %q, got %q", "create", body["message"])
	}
}

func TestReadJSON_Valid(t *testing.T) {
	request := httptest.NewRequest(
		http.MethodPost,
		"/tasks",
		strings.NewReader(`{"title":"Learn Go","priority":"high"}`),
	)

	var body testRequest

	err := readJSON(request, &body)
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if body.Title != "Learn Go" {
		t.Fatalf("expected title %q, got %q", "Learn Go", body.Title)
	}

	if body.Priority != "high" {
		t.Fatalf("expected priority %q, got %q", "high", body.Priority)
	}
}

func TestReadJSON_Invalid(t *testing.T) {
	request := httptest.NewRequest(
		http.MethodPost,
		"/tasks",
		strings.NewReader(`{"title": }`),
	)

	var body testRequest

	err := readJSON(request, &body)
	if err == nil {
		t.Fatalf("expected error, got nil")
	}
}

func TestWriteError(t *testing.T) {
	recorder := httptest.NewRecorder()

	writeError(recorder, http.StatusBadRequest, "error bad request")

	result := recorder.Result()
	defer result.Body.Close()

	if result.StatusCode != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", result.StatusCode)
	}

	var body errorResponse
	if err := json.NewDecoder(result.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response body: %v", err)
	}

	if body.Error != "error bad request" {
		t.Fatalf("expected message %q, got %q", "error bad request", body.Error)
	}
}
