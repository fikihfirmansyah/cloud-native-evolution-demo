package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// App menampung dependency yang dibutuhkan handler.
type App struct {
	DB       *pgxpool.Pool
	Hostname string
	Version  string
}

// Produk merepresentasikan satu baris tabel produk.
type Produk struct {
	ID    int    `json:"id"`
	Nama  string `json:"nama"`
	Harga int    `json:"harga"`
	Stok  int    `json:"stok"`
}

// handleProduk — GET /api/produk
// Mengembalikan seluruh produk dari database sebagai JSON array.
func (a *App) handleProduk(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	defer cancel()

	rows, err := a.DB.Query(ctx, "SELECT id, nama, harga, stok FROM produk ORDER BY id")
	if err != nil {
		log.Printf("query produk gagal: %v", err)
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "database tidak tersedia"})
		return
	}
	defer rows.Close()

	produk := []Produk{}
	for rows.Next() {
		var p Produk
		if err := rows.Scan(&p.ID, &p.Nama, &p.Harga, &p.Stok); err != nil {
			log.Printf("scan produk gagal: %v", err)
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "gagal membaca data"})
			return
		}
		produk = append(produk, p)
	}

	writeJSON(w, http.StatusOK, produk)
}

// handleHealth — GET /api/health
// Dipakai oleh: healthcheck Docker, target group ALB, dan badge frontend.
// handledBy menunjukkan instance mana yang menjawab — kunci demo scaling.
func (a *App) handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status":    "ok",
		"handledBy": a.Hostname,
		"version":   a.Version,
	})
}

// writeJSON menulis response JSON dengan status code.
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("encode JSON gagal: %v", err)
	}
}

// withCORS mengizinkan frontend (domain berbeda) memanggil API ini.
// Origin diatur lewat env CORS_ORIGIN; default "*" cukup untuk demo.
func withCORS(next http.Handler) http.Handler {
	origin := os.Getenv("CORS_ORIGIN")
	if origin == "" {
		origin = "*"
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
