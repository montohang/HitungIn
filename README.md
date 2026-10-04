# HitungIn

Pencatat keuangan pribadi **100% offline** — tanpa login, data tidak pernah meninggalkan HP.
Flutter · Android dulu · tema default **gelap**.

Status: **Tahap 6c — Ikon aplikasi** selesai: ikon peluncur resmi (adaptif + monokrom Android 13 + ikon Play Store),
3 ikon alternatif untuk Pro (Gelap, Emas, Terang), dan splash gelap tanpa kilatan putih.
Semua fitur yang dijanjikan di layar Pro sudah tersedia.

---

## Menjalankan pertama kali

Jalankan perintah di bawah dari dalam folder ini (`HitungIn`).

### 1. Font

Font dibundel di `assets/fonts/` (lisensi OFL, file lisensi ikut di folder yang sama) supaya aplikasi tetap offline:
Bricolage Grotesque Bold dan Plus Jakarta Sans 400–800.

### 2. Folder Android

Sudah dibuat (`flutter create --platforms=android --org id.hitungin --project-name hitungin .`) dengan penyesuaian:
- `MainActivity` memakai `FlutterFragmentActivity` (wajib untuk dialog sidik jari).
- Izin `USE_BIOMETRIC`.
- `allowBackup="false"` + `data_extraction_rules.xml`: database **tidak** ikut dicadangkan ke Google Drive.

### 3. Ambil dependensi, generate kode database, cek, dan jalankan

```bash
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter run
```

---

## Struktur

```
lib/
  main.dart                 # entry point
  app.dart                  # MaterialApp + tema terang/gelap + locale id_ID
  router.dart               # go_router
  core/
    theme/
      app_tokens.dart       # spasi (kelipatan 4), radius, durasi animasi, preset aksen
      app_colors.dart       # token warna terang & gelap (ThemeExtension)
      app_typography.dart   # skala teks Bricolage + Plus Jakarta Sans
      app_theme.dart        # ThemeData Material 3
      theme_controller.dart # pilihan mode & aksen (Riverpod), default: GELAP
      context_ext.dart      # context.colors / context.text / context.reduceMotion
    db/
      tables.dart           # skema: dompet, kategori, transaksi, budget, tagihan, pengaturan
      app_database.dart     # @DriftDatabase + migrasi + seed kategori bawaan
      default_data.dart     # kategori bawaan & kata kunci Catat Cepat
      connection.dart       # buka file SQLCipher (PRAGMA key) + cek cipher aktif
      db_key.dart           # kunci 256-bit acak di Android Keystore
      providers.dart        # appDatabaseProvider (Riverpod)
    branding/               # app_icon_variants.dart · app_icon_service.dart (ganti ikon peluncur)
    utils/rupiah.dart       # format Rp8.450.000, Rp3,12 jt, Rp164rb
    utils/dates.dart        # rentang bulan, jatuh tempo berikutnya
    utils/rupiah_input.dart # format isian nominal 2.500.000 saat mengetik
    utils/date_format.dart  # "Oktober 2026", "Kemarin", "08.42" tanpa data locale intl
    db/data_providers.dart  # StreamProvider bersama (saldo, ringkasan, riwayat, budget)
    widgets/month_switcher.dart, empty_state.dart
    security/secure_store.dart  # SecureStore (Keystore) + clockProvider
    widgets/                # Pressable, AppButton, AppCard, IconTile, AppChip,
                            # AppBadge, AppProgressBar, AppSegmentedControl,
                            # LogoMark, CountUpRupiah
  features/                 # satu folder per fitur (diisi bertahap)
    <fitur>/data/*_dao.dart # query per fitur (wallets, categories, transactions,
                            # budget, bills, settings)
    transactions/quick_entry_parser.dart  # "kopi 25rb gopay" → transaksi
    onboarding/             # splash, sapaan (3 halaman), buat PIN, sidik jari, dompet awal
    security/
      app_gate.dart         # GateState + gateRedirect (aturan router)
      pin_service.dart      # simpan/cek PIN, batas percobaan
      pin_hasher.dart       # PBKDF2-HMAC-SHA256 di isolate
      biometric_service.dart
      auto_lock.dart        # kunci setelah 30 dtk di latar belakang
      lock_screen.dart, widgets/pin_pad.dart
    shell/app_shell.dart    # navigasi bawah: Beranda · Riwayat · [Catat] · Laporan · Budget
    home/home_screen.dart   # sapaan, kartu saldo, Catat cepat, tagihan mendatang, budget, transaksi terbaru
    settings/               # Pengaturan, Tema & warna, widgets/settings_tile.dart (tile, sheet, dialog)
    wallets/wallets_screen.dart       # tambah/ubah/urutkan/arsipkan/hapus dompet
    categories/categories_screen.dart # tambah/ubah ikon & kata kunci/urutkan/arsipkan kategori
    bills/                  # bills_screen.dart (daftar, bayar, form) · data/bill_due.dart (status jatuh tempo)
    recurring/              # recurring_screen.dart · data/recurring_dao.dart (runDue: catat jadwal jatuh tempo)
    reports/widgets/        # daily_chart.dart · trend_chart.dart
    premium/                # premium_screen.dart · pro_controller.dart · data/ (limits, billing, entitlement)
    ads/                    # ad_ids.dart · ad_policy.dart · ads_service.dart (UMP + rewarded) · banner_slot.dart
    backup/                 # backup_screen.dart · data/backup_codec.dart · backup_service.dart · csv_export.dart
    security/security_screen.dart     # sidik jari, kunci otomatis, ganti PIN
    transactions/
      catat_screen.dart     # catat/ubah; kolom Catat cepat mengisi form otomatis
      riwayat_screen.dart   # per bulan, cari, filter jenis/kategori, dikelompokkan per hari
      tx_detail_screen.dart # detail, ubah, hapus
      widgets/tx_row.dart
    reports/laporan_screen.dart  # ringkasan, grafik harian, per kategori → riwayat
    budget/budget_screen.dart    # budget total & per kategori, sisa per hari
    dev/design_gallery_screen.dart
test/
  rupiah_test.dart          # format Rupiah
  theme_test.dart           # default gelap, kontras WCAG, galeri render
  quick_entry_parser_test.dart
  db/database_test.dart     # saldo, ringkasan, budget, tagihan, enkripsi file
  security/                 # aturan redirect, PIN & penguncian
  onboarding/flow_test.dart # alur onboarding & layar kunci lewat UI
  features/core_screens_test.dart  # Catat, transfer, detail, riwayat, laporan, budget lewat UI
  backup/backup_test.dart   # enkripsi cadangan, cadangkan→pulihkan, rollback, CSV
  recurring/recurring_test.dart  # jadwal berulang, susulan, tanggal 31, tren bulanan, filter dompet
  db/migration_test.dart    # v1 → v2 (skema & data lama) — helper di db/generated/ dari drift_dev
  branding/app_icon_test.dart  # kanal ganti ikon + konsistensi varian Dart ↔ manifest ↔ Kotlin ↔ berkas ikon
  premium/premium_test.dart # batas gratis, aturan iklan, simpan Pro, alur pembelian (Google Play palsu)
  settings/settings_logic_test.dart  # jatuh tempo, kunci otomatis, ganti PIN, kelola kategori/dompet
  helpers/fakes.dart        # TestEnv: DB memori, SecureStore memori, jam & biometrik palsu
```

Catatan tes widget: query Drift di luar frame wajib lewat `tester.runAsync`, dan DB ditutup
dengan `tester.runAsync(db.close)` — kalau tidak, tes menggantung di zona fake-async.

## Cadangan

- Berkas `.hitungin`: `HITUNGIN-BAK` · versi · iterasi · garam · nonce · ciphertext · MAC.
  Isi = JSON seluruh tabel → gzip → **AES-256-GCM**, kunci = **PBKDF2-HMAC-SHA256** (150.000 iterasi) dari kata sandi
  (min. 8 karakter). Header ikut diautentikasi; berkas yang diubah atau kata sandi salah ditolak.
- Disimpan/dibuka lewat pemilih berkas sistem (`file_picker`) — tidak ada unggahan otomatis.
- Pulihkan = **mengganti** semua data dalam satu transaksi (gagal → tidak ada yang berubah).
  PIN, kunci database, dan status onboarding tidak ikut (milik perangkat).
- CSV: UTF-8 + BOM, nominal bertanda (pengeluaran negatif), sel yang diawali `= + - @` diberi `'` agar tidak dieksekusi spreadsheet.

## Premium & iklan

"Offline" di HitungIn = **tanpa server untuk data**. Catatan keuangan tidak pernah dikirim;
internet hanya dipakai AdMob dan Google Play Billing.

| | Gratis | Pro (`hitungin_pro`, sekali bayar, saran Rp59.000) |
|---|---|---|
| Iklan | Banner di Beranda, Riwayat, Laporan | Tanpa iklan |
| Budget | Total + 2 kategori | Tak terbatas |
| Tagihan aktif | 3 | Tak terbatas |
| Laporan | Bulan ini & bulan lalu | Semua bulan |
| Ekspor CSV | 1× per iklan berhadiah | Bebas |
| Laporan tren 6/12 bulan & filter dompet | – | ✅ |
| Transaksi berulang (gaji, langganan) | – | ✅ (jadwal yang sudah ada tetap jalan walau Pro hilang) |
| Aksen warna | 6 | +4 (Plum, Laut, Kopi, Arang) |
| Catat, riwayat, dompet, cadangan terenkripsi | ✅ | ✅ |

Semua batas ada di `lib/features/premium/data/pro_limits.dart` (`FreeLimits`), aturan iklan di
`lib/features/ads/ad_policy.dart`. Tidak ada iklan di Catat, kunci/PIN, onboarding, Budget, Pengaturan, Cadangan.
Tidak ada interstitial. Permintaan iklan polos — tanpa kata kunci/penargetan dari data keuangan.

Pembelian dicek lokal (tanpa server): Pro aktif bila Google Play melaporkan `purchased`/`restored`,
lalu disimpan di Keystore supaya tetap berlaku offline. Pembelian selalu di-*acknowledge*
(kalau tidak, Google mengembalikan dana setelah 3 hari).

### Sebelum rilis (wajib)

1. **AdMob**: buat aplikasi & 2 unit iklan (banner adaptif, berhadiah). Ganti ID aplikasi di
   `android/app/src/main/AndroidManifest.xml`, dan isi unit iklan saat build:
   `flutter build appbundle --dart-define=ADMOB_BANNER_ID=… --dart-define=ADMOB_REWARDED_ID=…`
   (tanpa itu, ID **uji** Google yang dipakai).
2. **AdMob → Privasi & pesan**: buat pesan persetujuan GDPR (UMP) — dipakai otomatis oleh aplikasi.
3. **Play Console**: produk dalam aplikasi `hitungin_pro` (sekali beli), aktifkan; tambahkan penguji lisensi.
4. **Play Console → Keamanan data**: nyatakan *ID iklan* dikumpulkan oleh SDK AdMob untuk iklan;
   data keuangan **tidak** dikumpulkan/dibagikan. Centang "Berisi iklan".
5. Kebijakan privasi (URL) yang menjelaskan hal di atas.
6. Ikon Play Store: `branding/play_store_icon_512.png`.

## Ikon aplikasi

- Semua ikon dirender dari `LogoPainter` (logo Koin-H di kode), jadi selalu sama dengan logo di aplikasi.
  Setelah mengubah logo atau `lib/core/branding/app_icon_variants.dart`, jalankan:
  `flutter test tool/generate_icons_test.dart`
  → `android/app/src/main/res/mipmap-*` (adaptif 108dp + lama 48dp), `mipmap-anydpi-v26/*.xml`,
  `values/ic_launcher_colors.xml`, dan `branding/play_store_icon_512.png` (unggah ke Play Console).
- Ganti ikon (Pro) = mengaktifkan satu komponen peluncur dan mematikan yang lain (`MainActivity.setIcon`, kanal
  `id.hitungin/app_icon`). Ikon Standar memakai `LauncherActivity` (activity kecil yang meneruskan ke `MainActivity`),
  bukan alias, supaya bisa dimatikan **dan** `flutter run` tetap menemukan activity peluncur. Ikon lain = `activity-alias`.
- Menambah varian: tambah di `AppIconVariant`, di `iconComponents` (MainActivity.kt), alias di manifest, lalu jalankan
  generator. `test/branding/app_icon_test.dart` gagal bila salah satunya terlewat.
- Catatan perilaku launcher: setelah ganti ikon, ikon bisa hilang sebentar lalu muncul lagi; pintasan di layar utama
  perlu ditambahkan ulang. Ini sudah dijelaskan ke pengguna lewat snackbar.

## Rute

| Rute | Layar |
|---|---|
| `/home`, `/riwayat`, `/laporan`, `/budget` | 4 tab (StatefulShellRoute, state tiap tab dipertahankan) |
| `/riwayat?month=2026-10&category=3` | Riwayat terfilter (dipakai dari Laporan) |
| `/catat?text=kopi%2025rb` · `/catat?id=12` | Catat dengan isian awal · ubah transaksi |
| `/tx/12` | Detail transaksi |
| `/premium?from=budget` | Layar HitungIn Pro (judul mengikuti alasan) |
| `/pengaturan/berulang` | Transaksi berulang |
| `/pengaturan` (+ `/dompet`, `/kategori`, `/keamanan`, `/keamanan/ganti-pin`, `/cadangan`, `/tampilan`) · `/tagihan` | Pengaturan & sub-layarnya |

## Grafik

Laporan memakai satu warna (aksen) — tanpa palet kategorikal:
pengeluaran harian = kolom (≤24 px, ujung atas membulat 4 px, celah 2 px, garis bantu tipis),
ketuk kolom untuk melihat nilainya; per kategori = daftar batang terurut dengan nama, nominal, dan persen sebagai teks.

## Keamanan & alur masuk

- **Urutan**: Splash → Sapaan (3 hlm, nama panggilan opsional) → Buat PIN → Sidik jari (hanya bila HP mendukung) → Dompet awal → Beranda.
- **PIN** 6 digit, wajib. Yang terlalu mudah (111111, 123456, 654321) ditolak. Disimpan sebagai PBKDF2-HMAC-SHA256 (60.000 iterasi, garam acak) di Keystore — bukan di database.
- **Salah PIN**: 5× salah → tunggu 30 dtk, lalu 1, 2, 4, 8 mnt … maks. 15 mnt. Tetap berlaku walau aplikasi ditutup paksa.
- **Kunci otomatis** setelah 30 dtk di latar belakang; dialog sidik jari sendiri tidak memicunya.
- **Lupa PIN** tidak bisa direset (tidak ada server) — hanya lewat sidik jari atau hapus data + pulihkan cadangan.
- Router (`gateRedirect`) yang memutuskan layar: aplikasi yang ditutup di tengah onboarding dilanjutkan ke langkah dompet setelah PIN dimasukkan; setelah buka kunci, pengguna kembali ke halaman sebelumnya.

## Lapisan data

- **Drift** di atas **SQLCipher**. SQLCipher dibundel oleh paket `sqlite3` v3 lewat
  `hooks.user_defines.sqlite3.source: sqlcipher` di `pubspec.yaml`
  (paket `sqlcipher_flutter_libs` sudah EOL — jangan ditambahkan).
- Kunci database dibuat acak sekali, disimpan di Keystore (`flutter_secure_storage`).
  `applyCipherKey` menolak berjalan bila SQLCipher tidak termuat, supaya data tak pernah tersimpan polos.
- Nominal = `int` Rupiah, selalu positif; arah ditentukan `TxKind`. Saldo dompet dihitung dari transaksi, tidak disimpan.
- Kategori tidak dihapus, hanya diarsipkan (riwayat tetap utuh). Dompet hanya bisa dihapus bila belum dipakai.
- **Migrasi skema** (v1 → v2: tabel `recurring_txs` + `transactions.recurring_id`). Setelah mengubah `tables.dart`:
  1. naikkan `schemaVersion` dan tambahkan langkah di `onUpgrade`,
  2. `dart run build_runner build`,
  3. `dart run drift_dev schema dump lib/core/db/app_database.dart drift_schemas/`,
  4. `dart run drift_dev schema generate drift_schemas/ test/db/generated/`,
  5. tambah kasus di `test/db/migration_test.dart` (skema & data lama harus utuh).
- `drift` dan `drift_dev` **dikunci di 2.34.0**: versi `drift_dev` yang lebih baru butuh `meta` lebih baru
  daripada yang dibawa Flutter 3.41, dan versi yang tidak sama membuat `schema dump` gagal.

### Catat Cepat

| Ketik | Hasil |
|---|---|
| `kopi 25rb gopay` | Pengeluaran Rp25.000 · Makan & Minum · GoPay |
| `gaji 9,2jt bca` | Pemasukan Rp9.200.000 · Gaji · BCA |
| `+50rb dikasih ibu` | Pemasukan (tanda `+`) · Hadiah |
| `tf bca ke gopay 100rb` | Transfer BCA → GoPay |
| `topup gopay 100rb dari bca` | Transfer BCA → GoPay |
| `bensin 50.000 kemarin` | Tanggal kemarin · Transportasi |

Nominal: `25rb` `25k` `25 ribu` `25.000` `Rp25.000` `1,5jt` `1.5 juta` `1,25m`.
Bagian yang tidak terbaca dibiarkan kosong (`QuickEntry.isComplete == false`) agar layar Catat menanyakannya.

## Aturan design system (wajib diikuti di semua layar)

- Warna **selalu** dari `context.colors`, teks dari `context.text` — jangan menulis kode hex di layar.
- Jarak hanya dari `AppSpace` (2/4/8/12/16/20/24/32). Radius dari `AppRadius` (12/16/24/pil).
- Animasi pakai `AppMotion` dan wajib mati bila `context.reduceMotion` bernilai true.
- Elemen yang bisa diketuk dibungkus `Pressable` (atau komponen yang sudah memakainya).
- Area sentuh minimal 44×44.

Referensi desain: kanvas "HitungIn — UI Design v1" di Claude.

## Tahapan berikutnya

1. ~~Fondasi~~
2. ~~Lapisan data: Drift + SQLCipher, skema dompet/kategori/transaksi/budget/tagihan, parser "kopi 25rb gopay"~~
3. ~~Alur pertama kali buka: splash, onboarding, PIN + biometrik, dompet awal, layar kunci~~
4. ~~Layar inti: Beranda, Catat, Riwayat/Detail, Laporan, Budget~~
5. ~~Pengaturan & sisa MVP: dompet, kategori, tagihan, cadangan, CSV, ganti PIN, kunci otomatis, tema~~
6. ~~Premium + iklan~~
6b. ~~Fitur Pro: laporan tren 6–12 bulan & filter dompet, transaksi berulang, aksen tambahan~~
6c. ~~Ikon peluncur resmi + ikon alternatif Pro + splash gelap~~
7. Tes UI (widget) untuk layar Tahap 5–6b: Pengaturan, Dompet, Kategori, Tagihan, Keamanan/Ganti PIN, Cadangan, Tema, Premium, batas gratis, Transaksi berulang, tren & filter Laporan
8. Notifikasi pengingat tagihan (saat ini pengingat hanya tampil di dalam aplikasi)
