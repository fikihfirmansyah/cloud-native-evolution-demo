<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed database aplikasi (dipanggil oleh php artisan db:seed).
     */
    public function run(): void
    {
        $this->call(ProdukSeeder::class);
    }
}
