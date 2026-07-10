-- =============================================================
-- Seed data produk bertema Medan — dipakai demo-2 (Postgres di
-- Docker) dan demo-3 (Aurora PostgreSQL).
-- Demo-1 (Laravel + MySQL) memakai data yang SAMA lewat seeder
-- Laravel (lihat demo-1-legacy/database/seeders/ProdukSeeder.php)
-- karena sintaks MySQL sedikit berbeda.
--
-- Idempotent: aman dijalankan berulang kali (ON CONFLICT DO NOTHING).
-- =============================================================

CREATE TABLE IF NOT EXISTS produk (
    id    SERIAL PRIMARY KEY,
    nama  TEXT    NOT NULL UNIQUE,
    harga INTEGER NOT NULL, -- dalam Rupiah, tanpa desimal
    stok  INTEGER NOT NULL
);

INSERT INTO produk (nama, harga, stok) VALUES
    ('Durian Ucok (per buah)',          85000, 12),
    ('Bika Ambon Zulaikha (kotak)',     60000, 25),
    ('Teh Susu Telur (TST)',            18000, 40),
    ('Bolu Meranti Original',           55000, 30),
    ('Sirup Markisa Pohon Pinang',      35000, 18),
    ('Kopi Sidikalang (250 gr)',        48000, 22),
    ('Roti Ketawa (bungkus)',           15000, 50),
    ('Kacang Sihobuk (500 gr)',         42000, 15),
    ('Pancake Durian (isi 10)',         70000, 10),
    ('Manisan Jambu Medan',             25000, 35)
ON CONFLICT (nama) DO NOTHING;
