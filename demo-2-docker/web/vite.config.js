import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'

// Build menghasilkan static files murni (dist/) — bisa diserve oleh
// nginx (demo-2) maupun S3 + CloudFront (demo-3) tanpa perubahan.
export default defineConfig({
  plugins: [svelte()],
})
