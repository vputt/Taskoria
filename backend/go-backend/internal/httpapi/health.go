package httpapi

import "net/http"

type Health struct {
	Status  string `json:"status"`
	Service string `json:"service"`
}

func HealthHandler(w http.ResponseWriter, r *http.Request) {
	health := Health{
		Status:  "healthy",
		Service: "Taskoria API",
	}

	writeJSON(w, http.StatusOK, health)
}
