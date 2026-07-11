# Stress Test — Cloud Native Evolution Demo

**Tanggal:** 10 Juli 2026, 23:46–00:02 WIB (UTC+7)  
**Alat:** [hey](https://github.com/rakyll/hey) v0.1.4  
**Skenario:** identik untuk ketiga demo — beban **sangat berat**

## Parameter (sama untuk semua demo)

| Parameter | Nilai |
|---|---|
| Endpoint | `GET /api/produk` |
| Durasi | **5 menit** (`-z 5m`) |
| Concurrency | **150 koneksi paralel** (`-c 150`) |
| Timeout per request | 30 detik (`-t 30`) |
| Client | Laptop penguji → internet → target publik |

> Catatan: ini **7,5× lebih berat** dari skenario bawaan demo-1 (`20s`, `100` concurrent) dan setara `make load` demo-3.

---

## Target & infrastruktur

| Demo | URL | Server | Spesifikasi | Replika / task |
|---|---|---|---|---|
| **1 Legacy** | `https://demo-legacy-1.fikihfirmansyah.my.id` | `fikih@103.171.84.87` | 2 vCPU, 2 GB RAM | 1× PHP-FPM + MySQL + Nginx |
| **2 Docker** | `https://api-demo-docker-2.fikihfirmansyah.my.id` | `fikih@103.76.120.214` | 2 vCPU, 2 GB RAM | 3× API container + Traefik |
| **3 AWS** | `https://api-demo-aws-3.fikihfirmansyah.my.id` | ECS Fargate `ap-southeast-1` | 0.25 vCPU × 512 MB per task | 2 task (auto-scale max 6) |

---

## Ringkasan hasil

| Metrik | Demo 1 Legacy | Demo 2 Docker | Demo 3 AWS |
|---|---:|---:|---:|
| **Total request** | 40.738 | 380.299 | 457.289 |
| **Requests/sec** | 134,8 | 1.264,4 | 1.523,8 |
| **Error rate** | **0%** | **0%** | **0%** |
| **HTTP 200** | 40.738 | 380.299 | 457.289 |
| **Latensi rata-rata** | 1.108 s | 0.118 s | 0.098 s |
| **p50** | 0.999 s | 0.103 s | 0.089 s |
| **p90** | 1.571 s | 0.173 s | 0.132 s |
| **p99** | 2.239 s | 0.354 s | 0.327 s |
| **Terlambat** | 6.371 s | 1.774 s | 5.294 s |
| **Auto-scale** | ❌ tidak ada | ❌ manual only | ❌ **tidak terpicu** (tetap 2 task) |

### Visualisasi perbandingan

```
Requests/sec (lebih tinggi = lebih baik)

Demo 3 AWS     ████████████████████████████████████████  1.524
Demo 2 Docker  ██████████████████████████████████        1.264
Demo 1 Legacy  ████                                        135

p50 latency detik (lebih rendah = lebih baik)

Demo 3 AWS     █                                         0.089
Demo 2 Docker  █                                         0.103
Demo 1 Legacy  ███████████                               0.999
```

---

## Demo 1 — Legacy (Laravel + PHP-FPM + MySQL)

**Waktu:** 23:46:38 – 23:51:40 WIB

### Hasil `hey`

```
Requests/sec:   134.75
Average:        1.108 s
p50 / p90 / p99: 0.999 / 1.571 / 2.239 s
Slowest:        6.371 s
Status:         [200] 40738 — 0 error
```

### Server saat beban puncak (~60 detik)

| Metrik | Nilai |
|---|---|
| Load average | **3.82** (2 vCPU → ~190% utilized) |
| TCP established | 155 |
| TCP timewait | 7.597 |

### Server pasca-test

| Metrik | Nilai |
|---|---|
| Load average | 3.88, 3.25, 1.50 |
| Memory available | 1.4 GiB |

### Analisis

- Server **sangat terbebani** (load ~4× pada 2 core) tetapi **tidak ada request yang gagal** — PHP-FPM mengantre, bukan crash.
- Latensi **~10× lebih lambat** dari demo 2/3 — bottleneck di single-process PHP + MySQL di satu VPS.
- Sesuai narasi demo: viral traffic membuat aplikasi **ngos-ngosan** meski masih merespons 200.

---

## Demo 2 — Docker (Go API × 3 + Traefik)

**Waktu:** 23:52:09 – 23:57:10 WIB

### Hasil `hey`

```
Requests/sec:   1264.39
Average:        0.118 s
p50 / p90 / p99: 0.103 / 0.173 / 0.354 s
Slowest:        1.774 s
Status:         [200] 380299 — 0 error
```

### Container saat beban puncak (~60 detik)

| Container | CPU |
|---|---|
| demo-2-docker-api-6 | 18.6% |
| demo-2-docker-api-7 | 18.6% |
| demo-2-docker-api-8 | 18.5% |
| Load average (host) | 3.77 |

### Analisis

- **9,4× lebih banyak RPS** daripada demo 1 pada hardware serupa (2 vCPU / 2 GB).
- Beban tersebar merata ke **3 replica** (~18% CPU masing-masing) — Traefik load balancing bekerja.
- Latensi p50 **sub-100ms** — Go + connection pooling PostgreSQL jauh lebih efisien.
- **Tidak ada auto-scale** — kapasitas tetap 3 replica; untuk lebih banyak perlu `make scale-5` manual.

---

## Demo 3 — AWS (ECS Fargate + Aurora)

**Waktu:** 23:57:24 – 00:02:24 WIB

### Hasil `hey`

```
Requests/sec:   1523.84
Average:        0.098 s
p50 / p90 / p99: 0.089 / 0.132 / 0.327 s
Slowest:        5.294 s
Status:         [200] 457289 — 0 error
```

### ECS task count (polling tiap 30 detik)

| Waktu | Running | Desired |
|---|---|---|
| 23:57 – 00:02 (seluruh test) | **2** | **2** |

**Auto-scaling tidak terpicu** — CPU service tidak mencapai target 60% meski 457k request. Go API ringan + Aurora cukup untuk throughput ini pada 2 task × 0.25 vCPU.

### Analisis

- **Performa terbaik**: RPS tertinggi (1.524), latensi p50 terendah (89 ms).
- **457k request, 0 error** — ALB + multi-AZ ECS menahan beban tanpa degradasi.
- Auto-scale **tidak aktif** pada skenario ini — untuk memicu scale-out di demo, perlu beban lebih berat (`-c 300+`) atau durasi lebih lama, atau workload CPU-bound.

---

## Kesimpulan perbandingan

| Aspek | Demo 1 | Demo 2 | Demo 3 |
|---|---|---|---|
| Throughput | Keteteran (135 RPS) | Kuat (1.264 RPS) | Terkuat (1.524 RPS) |
| Latensi | Tinggi (~1s p50) | Rendah (~100ms) | Terendah (~89ms) |
| Ketahanan error | 0% error, tapi lambat | 0% error | 0% error |
| Scaling | Tidak mungkin | Manual (`scale-5`) | Otomatis (tidak terpicu kali ini) |
| Biaya saat test | VPS flat | VPS flat | Fargate + ALB + Aurora metered |

### Narasi presentasi

1. **Demo 1:** beban yang sama membuat server legacy **hampir saturasi** (load 4×) dengan latensi 10× lebih tinggi — tanpa crash, tapi pengalaman pengguna buruk.
2. **Demo 2:** kode Go yang sama di 3 container menangani **9× lebih banyak traffic** dengan latensi sub-100ms — bukti container + load balancer.
3. **Demo 3:** infrastruktur yang sama (kode demo-2) di AWS menangani **457k request tanpa error**, performa terbaik — meski auto-scale belum terlihat karena aplikasi terlalu efisien untuk parameter ini.

---

## Rekomendasi stress test lebih ekstrem

Untuk memicu **auto-scaling demo-3** dan **failure demo-1**:

```bash
# Lebih ekstrem — hati-hati biaya AWS
hey -z 10m -c 300 -t 30 https://api-demo-aws-3.fikihfirmansyah.my.id/api/produk

# Demo-1 — prediksi timeout/error
hey -z 5m -c 300 -t 10 https://demo-legacy-1.fikihfirmansyah.my.id/api/produk
```

---

## File log mentah

| Demo | Log |
|---|---|
| Demo 1 | `/tmp/stress-demo1.txt` |
| Demo 2 | `/tmp/stress-demo2.txt` |
| Demo 3 | `/tmp/stress-demo3.txt` |
| Demo 3 ECS poll | `/tmp/stress-demo3-ecs.log` |

---

*Dijalankan otomatis sebagai bagian persiapan demo cloud-native evolution.*
