<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Model produk oleh-oleh Medan.
 * Data sama persis dengan demo-2 dan demo-3 (lihat shared/seed-data.sql).
 */
class Produk extends Model
{
    // Nama tabel eksplisit karena bentuk jamak "produks" tidak lazim.
    protected $table = 'produk';

    // Tabel sederhana tanpa created_at/updated_at.
    public $timestamps = false;

    protected $fillable = ['nama', 'harga', 'stok'];
}
