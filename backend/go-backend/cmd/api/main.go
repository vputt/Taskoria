package main

import (
	"fmt"
	"net/http"
	"taskoria-go/internal/httpapi"
	//"github.com/gorilla/mux"
)

func main() {

	// mux := http.NewServeMux()

	// mux.HandleFunc(
	// 	"GET /health",
	// 	httpapi.HealthHandler,
	// )

	mux := httpapi.NewRouter()
	server := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}

	if err := server.ListenAndServe(); err != nil {
		fmt.Println("failed to start server: ", err)
		return
	}

	// http.HandleFunc("/health", httpapi.HealthHandler)

	// if err := http.ListenAndServe(":8080", nil); err != nil {
	// 	fmt.Println("failed to start server: ", err)
	// 	return
	// }

	// router := mux.NewRouter()

	// router.Path("/health").Methods("GET").HandlerFunc(httpapi.HealthHandler)
}
