package main

import (
	"fmt"
	"log"
	"net/http"
)

const serverMessage = "go start"

func main() {
	http.HandleFunc("/api/start", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if r.Method != http.MethodGet {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, serverMessage)
	})

	port := ":8080"
	log.Printf("MultiGames server listening on http://localhost%s", port)
	log.Printf("GET /api/start -> %q", serverMessage)
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal(err)
	}
}
