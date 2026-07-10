# =============================================================
# Multi-stage build — inilah salah satu poin utama demo.
#
# Stage 1 (builder): butuh toolchain Go lengkap (~800 MB image).
# Stage 2 (final)  : HANYA binary + CA cert di Alpine.
#
# Hasil akhir: image ±20 MB.
# Bandingkan dengan image Laravel + PHP-FPM + semua ekstensinya
# yang biasanya 400-500 MB. Lebih kecil = pull lebih cepat =
# deploy & scaling lebih cepat.
# =============================================================

# ---------- Stage 1: build ----------
FROM golang:1.25-alpine AS builder

WORKDIR /src

# Copy go.mod/go.sum dulu supaya layer dependency di-cache —
# rebuild hanya download ulang kalau dependency berubah.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# VERSION di-inject saat build (dari CI: git SHA pendek).
# Frontend menampilkan nilai ini di badge — bukti visual rolling deploy.
ARG VERSION=dev

# CGO_ENABLED=0 = binary statis, tidak butuh libc apa pun.
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /bin/api .

# ---------- Stage 2: final ----------
FROM alpine:3.21

# wget dipakai HEALTHCHECK; ca-certificates untuk TLS keluar (jaga-jaga).
RUN apk add --no-cache ca-certificates wget

COPY --from=builder /bin/api /usr/local/bin/api

ARG VERSION=dev
ENV VERSION=${VERSION} \
    PORT=8080

# Jalankan sebagai user non-root — praktik keamanan dasar container.
RUN adduser -D -u 10001 appuser
USER appuser

EXPOSE 8080

# Docker (dan Traefik lewat status health container) memakai ini
# untuk tahu container sehat atau tidak — dasar dari self-healing.
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:8080/api/health || exit 1

ENTRYPOINT ["api"]
