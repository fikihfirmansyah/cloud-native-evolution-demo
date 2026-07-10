<?php

namespace App\Http\Controllers;

use App\Models\Produk;

/**
 * Controller katalog produk — gaya Laravel klasik.
 *
 * Perhatikan yang TIDAK ada di sini (sengaja, bagian dari cerita demo):
 * - Tidak ada endpoint /api/health → tidak ada cara standar bagi
 *   load balancer / monitoring untuk tahu aplikasi sehat atau tidak.
 * - Tidak ada info instance/versi → kalau server diganti atau app
 *   di-deploy ulang, tidak ada bukti visual apa pun.
 */
class ProdukController extends Controller
{
    /**
     * GET /api/produk — list produk sebagai JSON via Eloquent.
     */
    public function api()
    {
        return response()->json(
            Produk::orderBy('id')->get(['id', 'nama', 'harga', 'stok'])
        );
    }

    /**
     * GET / — halaman katalog, di-render server-side (Blade).
     * Kalau MySQL mati, halaman ini langsung error 500 — tidak ada
     * degradasi anggun. Itu juga bagian dari demo.
     */
    public function index()
    {
        return view('produk', [
            'produk' => Produk::orderBy('id')->get(),
        ]);
    }
}
