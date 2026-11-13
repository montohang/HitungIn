# Ringkasan Produk HitungIn

Bahan rujukan singkat untuk konten (video, artikel, media sosial). Fakta di sini
mengikuti kode dan listingan Play Store per 13 November 2026 (versi 0.2.0). Kalau
ada yang berubah, perbarui file ini bersama perubahannya.

## Satu kalimat
HitungIn adalah aplikasi catat keuangan pribadi untuk Android yang **offline, tanpa
akun, dan terenkripsi** — catat secepat chat ("kopi 25rb gopay"), datanya tetap di HP.

## Untuk siapa
Pengguna Indonesia yang ingin mencatat uang harian tanpa ribet dan tanpa menyerahkan
data keuangan ke server mana pun: karyawan gajian bulanan, mahasiswa, pasangan muda,
siapa saja yang pakai banyak e-wallet.

## Pembeda utama
1. **Privat sungguhan** — tanpa akun, tanpa server, database terenkripsi (SQLCipher),
   dikunci PIN/biometrik. Backup juga terenkripsi dengan password.
2. **Catat secepat chat** — ketik bahasa sehari-hari: "kopi 25rb gopay", "2 ceban",
   "goban", "setengah juta"; alias dompet seperti gpay/spay/livin dikenali.
3. **Jatah aman per hari** — berapa yang boleh dipakai hari ini sampai gajian,
   dihitung dari saldo dan budget.
4. **Scan struk offline** — ML Kit di perangkat; total, tanggal, toko, dompet terbaca
   tanpa internet, foto tidak disimpan.
5. **Pro sekali bayar** — bukan langganan.

## Fitur (versi 0.2.0)
- **Inti:** catat cepat & keypad, transaksi favorit sekali ketuk, banyak dompet
  (tunai/bank/e-wallet) & pindah saldo, kategori dengan ikon/emoji, riwayat & filter.
- **Beranda:** total saldo, jatah hari ini, rekap minggu lalu, kartu yang bisa diatur.
- **Budget:** per kategori, template 50/30/20 dan 40/30/20/10, sisa akhir bulan bisa
  dipindah ke tabungan.
- **Tagihan & cicilan** dengan pengingat; **utang-piutang** dua arah; **patungan**
  bareng teman.
- **Target tabungan** dengan perayaan saat tercapai.
- **Rekap mingguan** (kartu bisa dibagikan) dan **rapor bulanan** (skor 6 aspek:
  Juara/Aman/Nanggung/Waduh).
- **Laporan** per kategori & arus kas; **export Excel & PDF**.
- **Kekayaan bersih:** aset, emas, investasi, utang, tren 12 bulan.
- **Backup** manual & **backup otomatis** harian ke folder pilihan (7 salinan).
- **Personalisasi:** tema gelap/terang, aksen warna, gaya ikon, widget layar utama,
  tile Quick Settings, ikon aplikasi alternatif.

## Harga & promo
- Gratis dengan iklan (AdMob). Data transaksi tidak dibagikan ke pengiklan.
- **HitungIn Pro:** Rp39.000 sekali bayar. Harga perkenalan Rp29.000 selama 30 hari
  setelah promo.
- **Promo perkenalan:** semua fitur Pro gratis sampai **28 Februari 2027**. Iklan tetap
  tampil kecuali Pro dibeli.
- Isi Pro: tanpa iklan, backup otomatis, scan struk & export tanpa batas, budget/
  tagihan/target tanpa batas, laporan semua bulan & kekayaan bersih lengkap, aksen
  warna & ikon alternatif.

## Status rilis
- Google Play: uji tertutup berjalan; permohonan akses produksi diajukan 13 Nov 2026.
- Nama di Play: "HitungIn - Catat Keuangan" · paket `com.capt.hitungin`.
- Kontak publik: halo.hitungin@gmail.com.

## Perjalanan pembuatan (bahan cerita)
Dibangun dengan Flutter + Claude Code, alur kerja: konsep → dokumen produk → desain
canvas → kode → uji emulator/HP → rilis.

| Tanggal | Tonggak |
|---|---|
| 4 Okt 2026 | Fondasi, data terenkripsi, layar inti (Beranda, Catat, Laporan, Budget), Pro + iklan |
| 5 Okt | Semua layar disamakan dengan desain canvas |
| 8 Okt | Persiapan rilis Play (signing, internal testing, kebijakan privasi) |
| 11 Okt | P1: jatah harian, catat cepat bahasa gaul, favorit, widget, emoji |
| 13 Okt | P2: cicilan, utang-piutang |
| 17 Okt | P2b: widget kustom, tema lanjutan, gaya ikon, Beranda kustom |
| 20–23 Okt | P3a–e: rekap mingguan, target tabungan, patungan, rapor bulanan, scan struk |
| 23–31 Okt | P3f–i: template budget, export Excel/PDF, kekayaan bersih, backup otomatis |
| 31 Okt | Rilis 0.2.0 |
| 12–13 Nov | Promo perkenalan, harga baru, iklan asli, listingan Play baru, ajukan produksi |

## Aset visual yang boleh dipakai
- Ikon: `branding/play_store/icon_512.png`
- Gambar fitur: `branding/play_store/feature_graphic_1024x500.png`
- Screenshot Play Store (1080×1920): `branding/play_store/screenshots/01…08`
- Rekaman layar baru: dari emulator dengan **data uji fiktif** saja.

## Jangan ditampilkan di konten publik
- Data keuangan asli, PIN, password backup, isi folder backup.
- Keystore, `key.properties`, ID akun developer, dasbor pendapatan, email pribadi,
  nomor telepon.
- Isi `docs/arsip-desain/` (arsip lokal, tidak dipublikasikan).
- Iklan AdMob asli yang diklik sendiri (dilarang kebijakan AdMob).
