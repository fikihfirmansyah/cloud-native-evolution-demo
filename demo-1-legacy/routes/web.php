<?php

use App\Http\Controllers\ProdukController;
use Illuminate\Support\Facades\Route;

// Halaman katalog (server-side rendered Blade)
Route::get('/', [ProdukController::class, 'index']);

// API produk. Catatan gaya legacy: route API ditaruh di web.php
// dengan prefix /api — umum di banyak proyek Laravel lama.
Route::get('/api/produk', [ProdukController::class, 'api']);

// Sengaja TIDAK ada /api/health — ini bagian dari cerita demo:
// tanpa health check, tidak ada yang bisa memantau aplikasi ini
// secara otomatis.
