<script>
  import { onMount, onDestroy } from 'svelte'

  // API base URL di-inject saat BUILD lewat env VITE_API_BASE.
  // Di demo-2: https://api.demo.example.com — di demo-3: URL ALB.
  // Frontend-nya sama persis, hanya nilai env yang beda.
  const API_BASE = import.meta.env.VITE_API_BASE || ''

  let produk = []
  let errorProduk = ''
  let health = null // { status, handledBy, version }
  let healthGagal = false
  let timer

  async function muatProduk() {
    try {
      const res = await fetch(`${API_BASE}/api/produk`)
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      produk = await res.json()
      errorProduk = ''
    } catch (e) {
      errorProduk = `Gagal memuat produk: ${e.message}`
    }
  }

  // Polling /api/health tiap 2 detik. Badge di layar akan menunjukkan
  // instance mana yang menjawab (handledBy) dan versi app (version) —
  // jadi saat demo scaling / rolling deploy, audiens MELIHAT perubahan
  // langsung di proyektor, bukan cuma di terminal.
  async function cekHealth() {
    try {
      const res = await fetch(`${API_BASE}/api/health`)
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      health = await res.json()
      healthGagal = false
    } catch {
      healthGagal = true
    }
  }

  onMount(() => {
    muatProduk()
    cekHealth()
    timer = setInterval(cekHealth, 2000)
  })

  onDestroy(() => clearInterval(timer))

  const rupiah = (n) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(n)
</script>

<main>
  <header>
    <h1>🛍️ Katalog Oleh-Oleh Medan</h1>
    <div class="badges">
      {#if healthGagal}
        <span class="badge badge-down">API DOWN</span>
      {:else if health}
        <span class="badge badge-instance" title="Instance yang menjawab request">
          🖥️ {health.handledBy}
        </span>
        <span class="badge badge-version" title="Versi aplikasi">
          v{health.version}
        </span>
      {:else}
        <span class="badge">menghubungi API…</span>
      {/if}
    </div>
  </header>

  {#if errorProduk}
    <p class="error">{errorProduk}</p>
  {:else if produk.length === 0}
    <p class="muted">Memuat produk…</p>
  {:else}
    <div class="grid">
      {#each produk as p (p.id)}
        <div class="card">
          <h2>{p.nama}</h2>
          <p class="harga">{rupiah(p.harga)}</p>
          <p class="stok">Stok: {p.stok}</p>
        </div>
      {/each}
    </div>
  {/if}
</main>

<style>
  :global(body) {
    margin: 0;
    font-family: system-ui, -apple-system, sans-serif;
    background: #f4f4f5;
    color: #18181b;
  }
  main {
    max-width: 960px;
    margin: 0 auto;
    padding: 1.5rem;
  }
  header {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
    margin-bottom: 1.5rem;
  }
  h1 {
    font-size: 1.4rem;
    margin: 0;
  }
  .badges {
    display: flex;
    gap: 0.5rem;
  }
  .badge {
    font-family: ui-monospace, monospace;
    font-size: 0.85rem;
    padding: 0.35rem 0.7rem;
    border-radius: 999px;
    background: #e4e4e7;
  }
  /* Warna berubah saat instance berganti — mudah terlihat di proyektor */
  .badge-instance {
    background: #dbeafe;
    color: #1d4ed8;
    font-weight: 600;
  }
  .badge-version {
    background: #dcfce7;
    color: #15803d;
    font-weight: 600;
  }
  .badge-down {
    background: #fee2e2;
    color: #b91c1c;
    font-weight: 700;
    animation: blink 1s infinite;
  }
  @keyframes blink {
    50% { opacity: 0.4; }
  }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 1rem;
  }
  .card {
    background: white;
    border-radius: 12px;
    padding: 1rem;
    box-shadow: 0 1px 3px rgb(0 0 0 / 0.08);
  }
  .card h2 {
    font-size: 1rem;
    margin: 0 0 0.5rem;
  }
  .harga {
    font-weight: 700;
    color: #b45309;
    margin: 0;
  }
  .stok {
    color: #71717a;
    font-size: 0.85rem;
    margin: 0.25rem 0 0;
  }
  .error {
    color: #b91c1c;
    background: #fee2e2;
    padding: 1rem;
    border-radius: 8px;
  }
  .muted {
    color: #71717a;
  }
</style>
