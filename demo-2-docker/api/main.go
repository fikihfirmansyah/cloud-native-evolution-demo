// Demo API katalog produk — Cloud-Native Evolution Demo.
//
// Prinsip 12-factor yang sengaja ditonjolkan di sini:
//   - Semua konfigurasi dari environment variable (tidak ada file config).
//   - Stateless: tidak menyimpan apa pun di disk/memori antar-request.
//   - Graceful shutdown: menangkap SIGTERM supaya rolling deploy mulus.
//
// Kode yang SAMA PERSIS ini jalan di Docker (demo-2) dan ECS Fargate
// (demo-3) tanpa modifikasi satu baris pun.
package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	// Konfigurasi murni dari env — tidak peduli jalan di mana.
	port := getenv("PORT", "8080")
	version := getenv("VERSION", "dev")
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL wajib di-set")
	}

	// hostname = identitas instance. Di Docker ini adalah container ID,
	// di ECS Fargate ini adalah task ID — badge "handledBy" di frontend
	// menampilkan nilai ini supaya audiens melihat instance berganti.
	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}

	pool, err := connectDB(dbURL)
	if err != nil {
		log.Fatalf("gagal konek database: %v", err)
	}
	defer pool.Close()

	app := &App{DB: pool, Hostname: hostname, Version: version}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/produk", app.handleProduk)
	mux.HandleFunc("GET /api/health", app.handleHealth)

	srv := &http.Server{
		Addr:              ":" + port,
		Handler:           withCORS(mux),
		ReadHeaderTimeout: 5 * time.Second,
	}

	// Jalankan server di goroutine supaya main bisa menunggu sinyal.
	go func() {
		log.Printf("api v%s listen di :%s (instance %s)", version, port, hostname)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("server error: %v", err)
		}
	}()

	// Graceful shutdown: saat orchestrator (Docker/ECS) kirim SIGTERM,
	// selesaikan dulu request yang sedang jalan (maks 10 detik) baru mati.
	// Inilah yang membuat rolling deploy tidak menjatuhkan satu request pun.
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGTERM, syscall.SIGINT)
	<-stop

	log.Println("menerima sinyal shutdown, menyelesaikan request berjalan...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("shutdown tidak mulus: %v", err)
	}
	log.Println("bye 👋")
}

// getenv membaca env var dengan nilai default.
func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
