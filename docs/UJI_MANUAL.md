# Uji manual HitungIn di HP sungguhan

Centang setiap butir. Catat model HP + versi Android bila ada yang aneh.
Semua alur di bawah juga sudah punya tes otomatis; daftar ini untuk hal yang **tidak bisa** dites otomatis
(sensor, notifikasi, launcher, Google Play, AdMob, performa, tampilan di layar asli).

## 0. Persiapan

- [ ] Pasang di HP (USB debugging aktif):
  ```bash
  flutter run --release
  ```
  `--release` supaya performa & animasi sesuai aslinya. Untuk melihat log pakai `flutter run` biasa.
- [ ] Siapkan minimal 2 HP bila bisa: satu Android 13+ (izin notifikasi, ikon bertema) dan satu Android 8–12.
- [ ] **Pembelian Pro hanya bisa diuji** setelah: (1) AAB diunggah ke jalur *Internal testing* di Play Console,
      (2) produk `hitungin_pro` dibuat & aktif, (3) akun Google di HP terdaftar sebagai *penguji lisensi*.
      Sebelum itu, layar Pro menampilkan "Produk belum tersedia" — itu normal.
- [ ] Iklan memakai **ID uji Google** → banner bertuliskan "Test Ad". Itu normal.

## 1. Pertama kali buka
- [ ] Splash gelap dengan logo (tidak ada kilatan putih), koin jatuh, lalu Sapaan.
- [ ] 3 halaman sapaan bisa digeser & tombol Lanjut; nama panggilan boleh kosong.
- [ ] Buat PIN: 123456 ditolak; konfirmasi beda → ulang; PIN valid tersimpan.
- [ ] Sidik jari: muncul hanya bila HP punya sensor; "Aktifkan" memunculkan dialog sistem; "Nanti saja" lanjut.
- [ ] Dompet awal: tambah GoPay/BCA dari chip, isi saldo (format 1.500.000 saat mengetik), Selesai → Beranda.
- [ ] Tutup paksa aplikasi di tengah onboarding (setelah PIN) → buka lagi → minta PIN → lanjut ke dompet awal.

## 2. Kunci
- [ ] Buka ulang aplikasi → layar kunci; sidik jari langsung ditawarkan bila aktif; batal → bisa pakai PIN.
- [ ] PIN salah 5× → tunggu 30 dtk (hitung mundur); tutup paksa & buka lagi → masih terkunci sementara.
- [ ] Ke latar belakang > 30 dtk → terkunci; < 30 dtk → tidak. Ubah ke "Segera" di Pengaturan → langsung terkunci.
- [ ] Dialog sidik jari / pemilih berkas / persetujuan iklan **tidak** memicu kunci otomatis.
- [ ] Tombol gembok di Beranda mengunci; setelah buka kunci kembali ke halaman sebelumnya.

## 3. Catat & data harian
- [ ] Catat cepat di Beranda: `kopi 25rb gopay`, `gaji 9,2jt bca`, `tf bca ke gopay 100rb`, `bensin 50.000 kemarin`.
- [ ] Layar Catat: keyboard angka, Rp dekat angka, pilih kategori/dompet/tanggal, Simpan → snackbar.
- [ ] Detail: ubah nominal, hapus (konfirmasi) → saldo dompet ikut berubah.
- [ ] Riwayat: ganti bulan, cari, filter jenis; dikelompokkan per hari dengan total harian.
- [ ] Laporan: angka ringkasan, ketuk kolom grafik harian → nilai; ketuk kategori → Riwayat terfilter.
- [ ] Budget: tambah total & kategori; ≥80% oranye "Hati-hati"; >100% merah "Lewat batas".

## 4. Pengaturan
- [ ] Nama panggilan berubah di sapaan Beranda.
- [ ] Dompet: tambah, urutkan (tahan & geser), arsipkan (hilang dari total), hapus dompet terpakai ditolak.
- [ ] Kategori: tambah dengan kata kunci → langsung dikenali Catat cepat; arsipkan.
- [ ] Tagihan: tambah, Bayar → tercatat & jatuh tempo maju; "Tagihan mendatang" di Beranda saat dekat/lewat.
- [ ] Tema: mode gelap/terang/AMOLED/sistem & aksen berubah langsung dan bertahan setelah aplikasi dibuka ulang.
- [ ] Ganti PIN: PIN lama salah ditolak; PIN baru berlaku setelah dikunci ulang.

## 5. Cadangan & ekspor
- [ ] Buat cadangan → simpan ke folder / Google Drive lewat pemilih berkas.
- [ ] Hapus data aplikasi (Pengaturan Android) → onboarding lagi → Pulihkan dari cadangan: kata sandi salah ditolak;
      benar → ringkasan isi → semua data kembali (dompet, transaksi, budget, tagihan, jadwal berulang, tema).
- [ ] Pulihkan di HP lain (pindah HP) bila memungkinkan.
- [ ] CSV (gratis): tawaran iklan berhadiah → tonton sampai selesai → berkas tersimpan; buka di Excel/Sheets:
      huruf & nominal benar, catatan berisi `=` tidak dieksekusi.

## 6. Iklan (versi gratis)
- [ ] Persetujuan iklan muncul sekali setelah onboarding (wajib di EEA; di Indonesia bisa tidak muncul).
- [ ] Banner hanya di Beranda, Riwayat, Laporan — **tidak** di Budget, Catat, kunci, Pengaturan, Cadangan.
- [ ] Banner tidak menutupi navigasi bawah & tidak ada kotak kosong saat iklan gagal dimuat (mode pesawat).
- [ ] Mode pesawat: aplikasi tetap berfungsi penuh tanpa internet.

## 7. Pro (setelah persiapan butir 0)
- [ ] Beli Pro → dialog Google Play → sukses → banner hilang, batas gratis hilang, "HitungIn Pro aktif".
- [ ] Bayar tertunda (metode "lambat" kartu uji) → "Menunggu pembayaran" → aktif otomatis setelah selesai.
- [ ] Hapus & pasang ulang aplikasi → "Pulihkan pembelian" → Pro aktif lagi.
- [ ] Laporan: filter dompet, tren 6/12 bulan.
- [ ] Transaksi berulang: jadwal mulai hari ini → langsung tercatat; ubah tanggal HP ke bulan depan → buka
      aplikasi → tercatat susulan + snackbar.
- [ ] Aksen Pro (Plum, Laut, Kopi, Arang).
- [ ] **Ikon alternatif** Gelap/Emas/Terang: ikon di launcher berganti (bisa butuh beberapa detik),
      aplikasi tetap bisa dibuka dari ikon baru, tidak ada ikon dobel. Uji di launcher bawaan HP & bila ada,
      launcher lain (Nova, Samsung One UI, MIUI/HyperOS).
- [ ] Android 13+: ikon bertema (wallpaper → "Ikon bertema") memakai logo monokrom.

## 8. Notifikasi tagihan (Pro)
- [ ] Nyalakan pengingat → dialog izin notifikasi (Android 13+).
- [ ] Tagihan jatuh tempo besok + jam pengingat beberapa menit lagi → **tutup aplikasi** → notifikasi muncul
      (boleh meleset beberapa menit).
- [ ] Layar kunci aman: isi notifikasi tersembunyi.
- [ ] Ketuk notifikasi saat aplikasi tertutup → minta PIN → layar Tagihan.
- [ ] Restart HP sebelum waktu pengingat → notifikasi tetap muncul.
- [ ] Bayar tagihan → notifikasi lama tidak muncul lagi; jadwal pindah ke jatuh tempo berikutnya.
- [ ] Matikan izin notifikasi dari pengaturan HP → kartu Tagihan menampilkan peringatan + tombol Izinkan.

## 9. Umum
- [ ] Ukuran huruf sistem besar (Pengaturan → Tampilan) → tidak ada teks terpotong parah / tombol tertutup.
- [ ] TalkBack: tombol keypad PIN, tab bawah, dan baris transaksi terbaca dengan jelas.
- [ ] "Kurangi animasi" aktif → animasi (splash, angka, progress) mati.
- [ ] Rotasi: tetap potret.
- [ ] Gestur kembali Android (predictive back) wajar di semua layar.
