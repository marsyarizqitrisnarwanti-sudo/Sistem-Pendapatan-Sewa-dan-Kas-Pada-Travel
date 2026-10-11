# Shabila Trans - Sistem Akuntansi

Aplikasi sederhana untuk mencatat pendapatan sewa, DP, kas, biaya perjalanan, komisi driver, dan biaya bulanan pada usaha shuttle bus travel.

## Struktur

- `frontend/` - HTML, CSS, dan JavaScript dashboard.
- `backend/schema.sql` - ERD empat entitas dan skema Supabase/Postgres.
- `backend/app.js` - API HTTP Node.js tanpa dependensi eksternal.

Entitas database: `pelanggan`, `driver`, `perjalanan_sewa`, dan `kas`. Tabel `ringkasan_perjalanan` adalah view laporan, bukan entitas.

## Menjalankan

1. Jalankan seluruh isi `backend/schema.sql` di SQL Editor Supabase.
2. Buka `frontend/index.html` langsung di browser. Frontend sudah menggunakan Supabase REST secara langsung, sehingga tidak perlu menginstal Node.js, menjalankan server, atau mengisi environment variable.
3. Dari menu `Pelanggan` dan `Driver`, tambahkan data pelanggan serta driver. Keduanya akan tersedia pada pilihan di form perjalanan.

## Deploy GitHub Pages

Workflow `.github/workflows/pages.yml` menerbitkan isi folder `frontend/` sebagai root website. Pada repository GitHub, buka **Settings > Pages** dan pilih **GitHub Actions** sebagai Build and deployment source. Commit dan push seluruh folder proyek ke branch `main`; setelah workflow `Deploy Shabila Trans to GitHub Pages` sukses, website menggunakan `frontend/app.js` dan tidak memuat `backend/app.js`.

Pada form perjalanan tersedia titik keberangkatan, titik turun, tanggal perjalanan, pilihan jam 06:00-21:00, dan kursi 1A sampai 4D. Jalankan seluruh isi file SQL di Supabase, termasuk saat memperbarui skema yang sudah ada; SQL akan membuat tabel driver dan menghubungkan nama driver pada perjalanan lama.

Frontend menggunakan endpoint Supabase REST dan publishable key. `backend/app.js` tetap tersedia sebagai opsi API lokal, tetapi tidak diperlukan untuk menjalankan frontend. Untuk produksi, tambahkan autentikasi Supabase dan ganti policy anon pada SQL.

## Catatan model bisnis

- Satu baris `perjalanan_sewa` mewakili satu perjalanan.
- Pelanggan dan driver disimpan pada tabel masing-masing dan direlasikan ke `perjalanan_sewa`.
- Komisi driver adalah tarif tetap per perjalanan.
- Bensin dicatat dari pengisian aktual.
- Bensin, tol, dan parkir dapat dibayar driver lalu dibukukan sebagai penggantian.
- DP otomatis membuat transaksi pemasukan di `kas`.
- Biaya rutin seperti servis, pajak, cicilan, dan gaji dicatat manual di `kas` dengan kategori `biaya_bulanan`.
