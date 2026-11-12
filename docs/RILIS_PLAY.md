# Rilis ke Google Play — Internal testing

Tujuan: menguji pembelian **HitungIn Pro** (`hitungin_pro`, sekali beli) lewat Google Play
dengan akun penguji lisensi (tidak ditagih sungguhan).

Paket: `com.capt.hitungin` · versi di `pubspec.yaml` (`version: x.y.z+KODE`).
Setiap unggahan baru ke Play **wajib** menaikkan angka setelah `+` (versionCode).

---

## 1. Buat kunci upload (sekali saja, dilakukan sendiri)

Kunci ini menandatangani setiap AAB yang diunggah. **Jangan hilang & jangan dibagikan.**
Simpan file `.jks` dan kata sandinya di tempat aman (mis. pengelola kata sandi) dan buat cadangan.

```bash
mkdir -p ~/keystores
keytool -genkey -v -keystore ~/keystores/hitungin-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`keytool` ada di JDK Android Studio bila tidak ditemukan:
`"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"`.

Lalu salin `android/key.properties.example` → `android/key.properties` dan isi kata sandinya.
File ini sudah di-`.gitignore` — jangan di-commit.

> Play App Signing (default) menyimpan kunci rilis di Google. Kunci di atas hanya
> "kunci upload": bila hilang, bisa direset lewat Play Console (butuh beberapa hari).

## 2. Build AAB

```bash
flutter build appbundle --release --no-tree-shake-icons
```

`--no-tree-shake-icons` wajib: gaya ikon (Garis, Isi, Bulat) dipilih saat aplikasi berjalan, jadi tidak ada glyph yang boleh dipangkas.
Versi di `pubspec.yaml` harus dinaikkan tiap unggah (`0.2.0+2` → nama 0.2.0, kode versi 2).

Hasil: `build/app/outputs/bundle/release/app-release.aab`.
Tanpa `android/key.properties`, AAB ditandatangani kunci debug dan **ditolak** Play Console.

Iklan: build ini memakai ID iklan uji AdMob (aman untuk internal testing). ID asli diisi
lewat `--dart-define` (lihat `lib/features/ads/ad_ids.dart`) sebelum rilis produksi.

## 3. Play Console — persiapan

1. **Profil pembayaran / merchant** (Setelan → Profil pembayaran) — wajib untuk produk berbayar.
2. **Buat aplikasi**: nama *HitungIn*, bahasa default Indonesia, *Aplikasi*, *Gratis*,
   centang deklarasi.
3. **Konten aplikasi** (Kebijakan → Konten aplikasi) — isi yang diminta:
   - Kebijakan privasi: https://appgratis.id/hitungin/privacy-policy
     (sumber: repo appgratis, `pages/hitungin/privacy-policy.vue`).
   - Iklan: **Ya, berisi iklan**.
   - Akses aplikasi: semua fitur bisa diakses tanpa login (PIN dibuat sendiri oleh pengguna).
   - Rating konten: isi kuesioner (aplikasi utilitas/keuangan, tanpa konten sensitif).
   - Target audiens: 18+ (atau 13+), bukan untuk anak.
   - Keamanan data: lihat bagian 6.
   - Aplikasi keuangan: pilih *tidak menyediakan* produk/layanan keuangan
     (hanya pencatat pribadi), bila ditanya.
   - ID iklan: **Ya** (dipakai SDK AdMob).

## 4. Rilis internal testing

1. Pengujian → **Pengujian internal** → tab *Penguji* → buat daftar email penguji
   (akun Google yang dipakai di HP uji), simpan.
2. Tab *Rilis* → **Buat rilis baru** → unggah `app-release.aab` → catatan rilis → Simpan →
   Tinjau → **Mulai peluncuran ke Pengujian internal**.
3. Salin **link undangan** (tab Penguji) → buka di HP uji dengan akun penguji →
   *Terima* → instal dari Play Store.
   - APK hasil `flutter run`/manual dengan tanda tangan lain harus di-uninstall dulu.

## 5. Produk Pro & penguji lisensi

1. Monetisasi → Produk → **Produk dalam aplikasi** → Buat produk
   (menu ini baru aktif setelah ada AAB dengan izin billing yang terunggah — langkah 4).
   - ID produk: `hitungin_pro` (harus persis; tidak bisa diubah)
   - Nama: HitungIn Pro · Deskripsi singkat fitur Pro
   - Harga: Rp39.000 (harga perkenalan Rp29.000 selama 30 hari sesudah promo) → Simpan → **Aktifkan**.
2. Setelan (menu utama Play Console, bukan per aplikasi) → **Pengujian lisensi** →
   tambahkan email penguji → respons lisensi `RESPOND_NORMALLY` → Simpan.
   Penguji lisensi melihat "Pesanan uji" dan tidak ditagih.
3. Produk baru bisa butuh beberapa jam sampai muncul di aplikasi.

## 6. Keamanan data (ringkasan untuk formulir)

- Data keuangan, PIN, catatan: **disimpan di perangkat saja**, terenkripsi (SQLCipher),
  tidak dikirim ke server mana pun → tidak "dikumpulkan" menurut definisi Play.
- Backup: file terenkripsi yang disimpan pengguna sendiri ke lokasi pilihannya.
- Dikumpulkan oleh SDK pihak ketiga (pengguna gratis):
  - Google Mobile Ads: ID perangkat/ID iklan, interaksi aplikasi, diagnostik —
    tujuan iklan & analitik, dibagikan ke Google. Persetujuan via formulir UMP.
  - Google Play Billing: riwayat pembelian (diproses oleh Google).
- Enkripsi saat transit: ya (SDK Google memakai HTTPS).
- Penghapusan data: pengguna bisa menghapus semua data di aplikasi / uninstall.

## 7. Uji pembelian (UJI_MANUAL poin 7)

- Beli Pro → dialog Play "Pesanan uji" → Pro aktif, iklan hilang.
- Kartu uji *"Disetujui lalu ditolak"* / *"lambat"* → status pending ditangani.
- Uninstall → instal lagi → **Pulihkan pembelian** → Pro aktif kembali.
- Refund (dengan cabut hak) → saat aplikasi dibuka, Pro dicabut (dicek ke daftar pembelian Play;
  offline/error tidak mengubah status). Akun Play yang berbeda dari akun pembeli juga dianggap tidak punya Pro.

## 8. Mengajukan akses produksi

Syarat akun pribadi baru: closed testing dengan minimal 12 penguji yang ikut serta terus-menerus 14 hari.
Setelah tombol **Ajukan permohonan untuk produksi** aktif (Dasbor):

1. Pastikan rilis pengujian tertutup terbaru sudah **terkirim untuk ditinjau** (Dasbor › Status pembaruan
   harus bukan "Belum dikirim untuk ditinjau"; kalau masih, buka Ringkasan publikasi › Kirim untuk ditinjau).
2. Jangan keluarkan penguji atau jeda track selama menunggu keputusan.
3. Formulir punya tiga bagian: tentang closed test (rekrut penguji, keterlibatan, ringkasan masukan),
   tentang aplikasi (sasaran pengguna, manfaat, perkiraan unduhan), dan kesiapan produksi
   (perubahan dari masukan, alasan siap). Jawab dengan fakta; catat masukan penguji & perubahan
   yang dibuat sejak closed test dimulai.
4. Peninjauan biasanya 7 hari atau kurang. Google bisa meminta pengujian tambahan.

## 9. Rilis produksi (pertama kali)

Akses produksi belum berarti rilis. Sebelum build produksi:

1. **Tanggal promo (P4):** hari terakhir promo = 3 bulan sejak tanggal rilis produksi yang direncanakan.
   Tulis di sini: `PROMO_END = ____-__-__`. Harga perkenalan berlaku 30 hari sesudahnya.
2. **ID iklan asli:**
   - ID aplikasi AdMob di `android/app/src/main/AndroidManifest.xml` (sekarang masih ID uji
     `ca-app-pub-3940256099942544~…`).
   - ID unit banner & rewarded lewat `--dart-define` (lihat `lib/features/ads/ad_ids.dart`).
3. **Versi:** naikkan `version:` di `pubspec.yaml` (nama & kode versi lebih tinggi dari rilis terakhir).
4. Build:

   ```bash
   flutter build appbundle --release --no-tree-shake-icons \
     --dart-define=PROMO_END=2027-02-28 \
     --dart-define=ADMOB_BANNER_ID=ca-app-pub-xxx/yyy \
     --dart-define=ADMOB_REWARDED_ID=ca-app-pub-xxx/zzz
   ```

   (ganti tanggal & ID dengan yang asli). Build tanpa `PROMO_END` = tanpa promo.
5. **Uji build itu sebelum diunggah:** pasang menimpa versi sebelumnya (data & PIN utuh), kartu Lainnya
   "Semua fitur Pro gratis · Sampai <tanggal>", iklan asli muncul (jangan diklik sendiri), scan struk,
   PDF/Excel, backup otomatis.
6. **Play Console:**
   - Harga `hitungin_pro`: Rp39.000. Saat promo berakhir, ubah ke **Rp29.000** selama 30 hari harga
     perkenalan, lalu kembali ke Rp39.000. Aplikasi menampilkan harga dari Google Play, jadi tidak perlu build.
   - Halaman Play Store: tulis "Semua fitur Pro gratis sampai <tanggal>" di deskripsi; hapus saat promo selesai.
   - Keamanan data: tetap seperti bagian 6 (backup otomatis & password-nya tersimpan di HP, tidak dikirim).
7. Rilis bertahap (mis. 20% → 50% → 100%) supaya masalah ketahuan sebelum sampai ke semua pengguna.
