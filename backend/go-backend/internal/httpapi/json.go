package httpapi

import (
	"encoding/json"
	"fmt"
	"net/http"
)

type errorResponse struct {
	Error string `json:"error"`
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	body, err := json.Marshal(data)
	if err != nil {
		http.Error(w, "internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if _, err := w.Write(body); err != nil {
		fmt.Println("failed to write response:", err)
	}
}

func readJSON(r *http.Request, dst any) error {
	return json.NewDecoder(r.Body).Decode(dst)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, errorResponse{
		Error: message,
	})
}
