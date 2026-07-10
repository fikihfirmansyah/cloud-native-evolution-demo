<?php

namespace Database\Seeders;

use App\Models\Produk;
use Illuminate\Database\Seeder;

/**
 * Data produk SAMA dengan shared/seed-data.sql (dipakai demo-2 & demo-3).
 * Ditulis ulang sebagai seeder karena demo-1 memakai MySQL + Eloquent,
 * sedangkan file SQL bersama bersintaks PostgreSQL.
 */
class ProdukSeeder extends Seeder
{
    public function run(): void
    {
        $produk = [
            ['nama' => 'Durian Ucok (per buah)',      'harga' => 85000, 'stok' => 12],
            ['nama' => 'Bika Ambon Zulaikha (kotak)', 'harga' => 60000, 'stok' => 25],
            ['nama' => 'Teh Susu Telur (TST)',        'harga' => 18000, 'stok' => 40],
            ['nama' => 'Bolu Meranti Original',       'harga' => 55000, 'stok' => 30],
            ['nama' => 'Sirup Markisa Pohon Pinang',  'harga' => 35000, 'stok' => 18],
            ['nama' => 'Kopi Sidikalang (250 gr)',    'harga' => 48000, 'stok' => 22],
            ['nama' => 'Roti Ketawa (bungkus)',       'harga' => 15000, 'stok' => 50],
            ['nama' => 'Kacang Sihobuk (500 gr)',     'harga' => 42000, 'stok' => 15],
            ['nama' => 'Pancake Durian (isi 10)',     'harga' => 70000, 'stok' => 10],
            ['nama' => 'Manisan Jambu Medan',         'harga' => 25000, 'stok' => 35],
        ];

        // Idempotent: aman dijalankan berulang (upsert berdasarkan nama).
        foreach ($produk as $p) {
            Produk::updateOrCreate(['nama' => $p['nama']], $p);
        }
    }
}
