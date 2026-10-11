-- Shabila Trans: ERD empat entitas
-- pelanggan, driver 1 --- n perjalanan_sewa 1 --- n kas

create extension if not exists pgcrypto;

create table if not exists driver (
  id uuid primary key default gen_random_uuid(),
  nama text not null,
  nomor_telepon text,
  created_at timestamptz not null default now()
);

create table if not exists pelanggan (
  id uuid primary key default gen_random_uuid(),
  nama text not null,
  nomor_telepon text,
  email text,
  alamat text,
  catatan text,
  created_at timestamptz not null default now()
);

alter table pelanggan add column if not exists catatan text;

create table if not exists perjalanan_sewa (
  id uuid primary key default gen_random_uuid(),
  pelanggan_id uuid not null references pelanggan(id) on delete restrict,
  tanggal_perjalanan date not null,
  titik_keberangkatan text,
  titik_turun text,
  jam_keberangkatan time,
  tempat_duduk text[] not null default '{}',
  rute text not null,
  kendaraan text not null,
  nama_driver text not null,
  driver_id uuid references driver(id) on delete restrict,
  status text not null default 'terjadwal' check (status in ('terjadwal', 'berjalan', 'selesai', 'dibatalkan')),
  nilai_sewa numeric(14,2) not null check (nilai_sewa >= 0),
  diskon numeric(14,2) not null default 0 check (diskon >= 0),
  dp numeric(14,2) not null default 0 check (dp >= 0),
  bensin_aktual numeric(14,2) not null default 0 check (bensin_aktual >= 0),
  tol numeric(14,2) not null default 0 check (tol >= 0),
  parkir numeric(14,2) not null default 0 check (parkir >= 0),
  komisi_driver numeric(14,2) not null default 0 check (komisi_driver >= 0),
  status_penggantian text not null default 'belum_diganti' check (status_penggantian in ('belum_diganti', 'sebagian', 'sudah_diganti')),
  catatan text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint diskon_tidak_melebihi_sewa check (diskon <= nilai_sewa),
  constraint dp_tidak_melebihi_total check (dp <= nilai_sewa - diskon)
);

alter table perjalanan_sewa add column if not exists titik_keberangkatan text;
alter table perjalanan_sewa add column if not exists titik_turun text;
alter table perjalanan_sewa add column if not exists jam_keberangkatan time;
alter table perjalanan_sewa add column if not exists tempat_duduk text[] not null default '{}';
alter table perjalanan_sewa add column if not exists driver_id uuid references driver(id) on delete restrict;

insert into driver (nama)
select distinct on (lower(trim(p.nama_driver))) trim(p.nama_driver)
from perjalanan_sewa p
where nullif(trim(p.nama_driver), '') is not null
  and not exists (
    select 1 from driver d
    where lower(trim(d.nama)) = lower(trim(p.nama_driver))
  )
order by lower(trim(p.nama_driver)), trim(p.nama_driver);

update perjalanan_sewa p
set driver_id = d.id
from driver d
where p.driver_id is null
  and lower(trim(p.nama_driver)) = lower(trim(d.nama));

create table if not exists kas (
  id uuid primary key default gen_random_uuid(),
  perjalanan_id uuid references perjalanan_sewa(id) on delete set null,
  tanggal_transaksi date not null default current_date,
  jenis text not null check (jenis in ('pemasukan', 'pengeluaran')),
  kategori text not null check (kategori in ('dp_sewa', 'pelunasan_sewa', 'penggantian_bensin', 'penggantian_tol', 'penggantian_parkir', 'komisi_driver', 'biaya_bulanan', 'lainnya')),
  keterangan text not null,
  jumlah numeric(14,2) not null check (jumlah > 0),
  metode_pembayaran text not null default 'tunai' check (metode_pembayaran in ('tunai', 'transfer', 'qris', 'lainnya')),
  created_at timestamptz not null default now()
);

create index if not exists idx_perjalanan_tanggal on perjalanan_sewa(tanggal_perjalanan desc);
create index if not exists idx_perjalanan_pelanggan on perjalanan_sewa(pelanggan_id);
create index if not exists idx_perjalanan_driver on perjalanan_sewa(driver_id);
create index if not exists idx_kas_tanggal on kas(tanggal_transaksi desc);
create index if not exists idx_kas_perjalanan on kas(perjalanan_id);

alter table driver enable row level security;
alter table pelanggan enable row level security;
alter table perjalanan_sewa enable row level security;
alter table kas enable row level security;

-- Policy awal untuk aplikasi internal/demo. Tambahkan autentikasi sebelum produksi.
drop policy if exists driver_akses_anon on driver;
create policy driver_akses_anon on driver for all using (true) with check (true);
drop policy if exists pelanggan_akses_anon on pelanggan;
create policy pelanggan_akses_anon on pelanggan for all using (true) with check (true);
drop policy if exists perjalanan_akses_anon on perjalanan_sewa;
create policy perjalanan_akses_anon on perjalanan_sewa for all using (true) with check (true);
drop policy if exists kas_akses_anon on kas;
create policy kas_akses_anon on kas for all using (true) with check (true);

create or replace view ringkasan_perjalanan as
select
  p.id,
  p.tanggal_perjalanan,
  p.rute,
  p.kendaraan,
  p.nama_driver,
  p.status,
  c.nama as nama_pelanggan,
  (p.nilai_sewa - p.diskon) as pendapatan_bersih,
  (p.bensin_aktual + p.tol + p.parkir + p.komisi_driver) as total_biaya_perjalanan,
  (p.nilai_sewa - p.diskon - p.bensin_aktual - p.tol - p.parkir - p.komisi_driver) as laba_perjalanan,
  p.dp,
  p.status_penggantian
from perjalanan_sewa p
join pelanggan c on c.id = p.pelanggan_id;
