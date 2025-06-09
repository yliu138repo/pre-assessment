package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

type RequestPayload struct {
	Fail bool `json:"fail"`
}

func main() {
	port := os.Getenv("LISTEN_PORT")
	if port == "" {
		log.Fatal("LISTEN_PORT environment variable not set")
	}

	address := ":" + port

	srv := &http.Server{
		Addr:    address,
		Handler: http.DefaultServeMux,
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// to simulate an failure
		if r.Method == http.MethodPost {
			var payload RequestPayload
			err := json.NewDecoder(r.Body).Decode(&payload)
			if err != nil {
				http.Error(w, "Invalid JSON", http.StatusBadRequest)
				return
			}
			if payload.Fail {
				log.Println("Simulating failure as per request payload")
				os.Exit(1) // Exit with a non-zero status code to simulate failure
			}
		}
		fmt.Fprintln(w, "Hello, World!")
	})

	// Channel to listen for interrupt or terminate signals
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Printf("Server listening on http://%s\n", address)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Block until a signal is received
	<-stop

	log.Println("Shutting down server...")

	// Create a timeout too when the server fails to shutdown outside the threshold
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exiting")
}
