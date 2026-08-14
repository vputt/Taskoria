package httpapi

import (
	"net/http"
)

type Health struct {
	Status  string `json:"status"`
	Service string `json:"service"`
}

/*
pattern: /health
method: GET

succeed:
	- status code: 200 ok
	- response body: json represent server status
*/

func HealthHandler(w http.ResponseWriter, r *http.Request) {
	health := Health{
		Status:  "healthy",
		Service: "Taskoria API",
	}
	writeJSON(w, http.StatusOK, health)
}
