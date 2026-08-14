package httpapi

import (
	"net/http"
)

func NewRouter() http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /health", HealthHandler)

	return mux
}
