# =============================================================
# Multi-stage build frontend:
# Stage 1: build Svelte → static files (butuh Node, ~1 GB image)
# Stage 2: serve static files via nginx-alpine (~50 MB total)
# =============================================================

# ---------- Stage 1: build ----------
FROM node:24-alpine AS builder

WORKDIR /src

# Layer caching: install dependency dulu, baru copy source.
COPY package.json package-lock.json* ./
RUN npm ci || npm install

COPY . .

# API base URL harus diketahui saat BUILD karena hasilnya static files.
# Di-set dari build arg oleh CI / docker compose.
ARG VITE_API_BASE=https://api.demo.example.com
ENV VITE_API_BASE=${VITE_API_BASE}

RUN npm run build

# ---------- Stage 2: serve ----------
FROM nginx:alpine

COPY --from=builder /src/dist /usr/share/nginx/html

# Konfigurasi nginx minimal: serve SPA, fallback ke index.html.
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD wget -q --spider http://127.0.0.1:80/ || exit 1
