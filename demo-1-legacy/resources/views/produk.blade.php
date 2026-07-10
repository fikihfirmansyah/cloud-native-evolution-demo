<!doctype html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Katalog Oleh-Oleh Medan (Legacy)</title>
    <style>
        body { margin: 0; font-family: system-ui, sans-serif; background: #f4f4f5; color: #18181b; }
        main { max-width: 960px; margin: 0 auto; padding: 1.5rem; }
        header { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: .75rem; margin-bottom: 1.5rem; }
        h1 { font-size: 1.4rem; margin: 0; }
        .badge { font-family: ui-monospace, monospace; font-size: .85rem; padding: .35rem .7rem; border-radius: 999px; background: #fef3c7; color: #92400e; font-weight: 600; }
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 1rem; }
        .card { background: #fff; border-radius: 12px; padding: 1rem; box-shadow: 0 1px 3px rgb(0 0 0 / .08); }
        .card h2 { font-size: 1rem; margin: 0 0 .5rem; }
        .harga { font-weight: 700; color: #b45309; margin: 0; }
        .stok { color: #71717a; font-size: .85rem; margin: .25rem 0 0; }
    </style>
</head>
<body>
<main>
    <header>
        <h1>🛍️ Katalog Oleh-Oleh Medan</h1>
        {{-- Satu-satunya "identitas server": hostname VPS, di-render
             server-side. Tidak ada versi app, tidak ada health check —
             bandingkan dengan badge dinamis di demo-2/3. --}}
        <span class="badge">server: {{ gethostname() }}</span>
    </header>

    <div class="grid">
        @foreach ($produk as $p)
            <div class="card">
                <h2>{{ $p->nama }}</h2>
                <p class="harga">Rp{{ number_format($p->harga, 0, ',', '.') }}</p>
                <p class="stok">Stok: {{ $p->stok }}</p>
            </div>
        @endforeach
    </div>
</main>
</body>
</html>
