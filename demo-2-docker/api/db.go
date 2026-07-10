package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// connectDB membuka connection pool ke PostgreSQL dengan retry.
// Retry penting di dunia container: database bisa saja belum siap
// beberapa detik saat container api start (misal setelah reboot server).
// Daripada langsung mati, kita coba lagi — orchestrator juga akan
// me-restart container jika akhirnya gagal.
func connectDB(dbURL string) (*pgxpool.Pool, error) {
	const maxAttempts = 10

	var lastErr error
	for attempt := 1; attempt <= maxAttempts; attempt++ {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		pool, err := pgxpool.New(ctx, dbURL)
		if err == nil {
			err = pool.Ping(ctx)
			if err == nil {
				cancel()
				log.Printf("database terhubung (percobaan ke-%d)", attempt)
				return pool, nil
			}
			pool.Close()
		}
		cancel()
		lastErr = err
		log.Printf("database belum siap (percobaan %d/%d): %v", attempt, maxAttempts, err)
		time.Sleep(2 * time.Second)
	}
	return nil, fmt.Errorf("menyerah setelah %d percobaan: %w", maxAttempts, lastErr)
}
