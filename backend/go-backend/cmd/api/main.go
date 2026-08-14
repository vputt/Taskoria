package main

import (
	"fmt"
	"net/http"
	"taskoria-go/internal/httpapi"
)

func main() {
	server := &http.Server{
		Addr:    ":8080",
		Handler: httpapi.NewRouter(),
	}

	if err := server.ListenAndServe(); err != nil {
		fmt.Println("failed to start server:", err)
		return
	}
}
