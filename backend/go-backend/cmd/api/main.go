package main

import (
	"fmt"
	"net/http"

	"taskoria-go/internal/httpapi"
	"taskoria-go/internal/service"
	"taskoria-go/internal/storage/memory"
)

func main() {
	taskRepository := memory.NewTaskRepository()
	taskService := service.NewTaskService(taskRepository)
	taskHandler := httpapi.NewTaskHandler(taskService)
	router := httpapi.NewRouter(taskHandler)

	server := &http.Server{
		Addr:    ":8080",
		Handler: router,
	}

	if err := server.ListenAndServe(); err != nil {
		fmt.Println("failed to start server:", err)
		return
	}
}
