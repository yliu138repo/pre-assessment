package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	port := os.Getenv("LISTEN_PORT")
	if port == "" {
		log.Fatal("LISTEN_PORT environment variable not set")
	}

	address := ":" + port

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Hello, World!")
	})

	log.Printf("Server listening on http://%s\n", address)
	err := http.ListenAndServe(address, nil)
	if err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
