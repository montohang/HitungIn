# HitungIn

Pencatat keuangan pribadi **100% offline** — tanpa login, data tidak pernah meninggalkan HP.
Flutter · Android dulu · tema default **gelap**.

Status: **Tahap 4 — Layar inti** selesai: Beranda, Catat (dengan Catat Cepat), Riwayat + Detail,
Laporan, dan Budget dalam navigasi 4 tab + tombol Catat di tengah.
*Design Gallery* bisa dibuka dari ikon palet di beranda (mode debug).

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
    home/home_screen.dart   # sapaan, kartu saldo, Catat cepat, budget, transaksi terbaru, dompet
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
  helpers/fakes.dart        # TestEnv: DB memori, SecureStore memori, jam & biometrik palsu
```

Catatan tes widget: query Drift di luar frame wajib lewat `tester.runAsync`, dan DB ditutup
dengan `tester.runAsync(db.close)` — kalau tidak, tes menggantung di zona fake-async.

## Rute

| Rute | Layar |
|---|---|
| `/home`, `/riwayat`, `/laporan`, `/budget` | 4 tab (StatefulShellRoute, state tiap tab dipertahankan) |
| `/riwayat?month=2026-10&category=3` | Riwayat terfilter (dipakai dari Laporan) |
| `/catat?text=kopi%2025rb` · `/catat?id=12` | Catat dengan isian awal · ubah transaksi |
| `/tx/12` | Detail transaksi |

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
- Setelah mengubah `tables.dart` atau DAO: jalankan `dart run build_runner build`, naikkan
  `schemaVersion`, dan tambahkan langkah di `migration`.

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
5. Pengaturan & sisa MVP, lalu Premium + iklan
