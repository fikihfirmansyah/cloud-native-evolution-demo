<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('produk', function (Blueprint $table) {
            $table->id();
            $table->string('nama')->unique();
            $table->unsignedInteger('harga'); // Rupiah, tanpa desimal
            $table->unsignedInteger('stok');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('produk');
    }
};
