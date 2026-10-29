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
- [x] Splash gelap dengan logo (tidak ada kilatan putih), koin jatuh, lalu Sapaan.
- [x] 4 halaman sapaan bisa digeser & tombol Lanjut; nama panggilan boleh kosong.
- [x] Buat PIN: 123456 ditolak; konfirmasi beda → ulang; PIN valid tersimpan.
- [x] Sidik jari: muncul hanya bila HP punya sensor; "Aktifkan" memunculkan dialog sistem; "Nanti saja" lanjut.
- [x] Dompet awal: tambah GoPay/BCA dari chip, isi saldo (format 1.500.000 saat mengetik), Selesai → Beranda.
- [x] Tutup paksa aplikasi di tengah onboarding (setelah PIN) → buka lagi → minta PIN → lanjut ke dompet awal.

## 2. Kunci
- [x] Buka ulang aplikasi → layar kunci; sidik jari langsung ditawarkan bila aktif; batal → bisa pakai PIN.
- [x] PIN salah 5× → tunggu 30 dtk (hitung mundur); tutup paksa & buka lagi → masih terkunci sementara.
- [x] Ke latar belakang > 30 dtk → terkunci; < 30 dtk → tidak. Ubah ke "Segera" di Lainnya › Keamanan → langsung terkunci.
- [x] Dialog sidik jari / pemilih berkas / persetujuan iklan **tidak** memicu kunci otomatis.
- [x] Tombol gembok (🔒, pojok kanan atas Beranda, sebelah 👁) langsung mengunci aplikasi tanpa menunggu kunci otomatis.
- [x] Kembali ke halaman semula setelah buka kunci: buka Riwayat → ketuk satu transaksi (Detail) → tekan Home > 30 dtk
      (atau set kunci otomatis "Segera") → buka HitungIn → masukkan PIN → yang tampil **Detail transaksi tadi**, bukan Beranda.

## 3. Catat & data harian
- [x] Navigasi bawah: Beranda · Laporan · **+** · Budget · Lainnya. Riwayat dibuka dari "Lihat semua" (ada tombol kembali).
- [x] Beranda: 👁 menyembunyikan saldo (tetap tersembunyi setelah app dibuka ulang); lencana "Data di HP-mu · backup …" (oranye bila belum/lebih dari 14 hari, ketuk → Backup); "Total saldo · N dompet ›" → Dompet; kartu Budget dengan chip kategori ≥80%.
- [x] Hari pertama (belum ada transaksi): contoh `kopi 25rb gopay` dll. bisa diketuk, checklist "Siapkan HitungIn n dari 4".
- [x] Catat cepat di Beranda: `kopi 25rb gopay`, `gaji 9,2jt bca`, `tf bca ke gopay 100rb`, `bensin 50.000 kemarin`.
- [x] Layar Catat: keypad sendiri (1–9, 000, 0, ⌫) tanpa keyboard HP; kategori satu baris geser; kartu **Dari dompet** & **Tanggal** membuka lembar pilihan (Hari ini / Kemarin / Pilih tanggal lain); Pindah Saldo menampilkan kartu Dari → Ke + info; tombol "Simpan · Rp…". Saat mengetik catatan, keypad tersembunyi.
- [x] Detail: Edit (kanan atas), chip "Pengeluaran · dicatat manual/otomatis/dari tagihan", kartu dampak budget, **Duplikat** → form terisi (tanggal hari ini), **Hapus** → lembar konfirmasi → snackbar "Transaksi dihapus · Urungkan" mengembalikan transaksi & saldo.
- [x] Riwayat: cari nama/catatan/**nominal** (`50rb`, `1,5jt`, `25.000`); chip jenis; kartu Masuk/Keluar; tombol filter → pilih bulan & kategori (titik di tombol saat filter aktif); "Tidak ada transaksi yang cocok".
- [x] Laporan: < 3 transaksi → "Laporan muncul setelah 3 transaksi" (cincin n/3). Selain itu: pil bulan, ringkasan, donat per kategori (ketuk legenda → Riwayat terfilter), grafik harian, Arus kas 6 bulan (12 bulan = Pro), kartu Rata-rata per hari & Kategori terbesar.
- [x] Budget: kosong → "Atur manual" / "Saran dari kebiasaanmu". Atur budget: Ubah total, −/+ per kategori (50rb), ketuk angka untuk mengetik, rata-rata 3 bulan, kategori ke-3 versi gratis → Pro, sakelar "Peringatan di 80%", Simpan budget.
- [x] Budget: kartu Terpakai dengan penanda "Hari ini", kartu peringatan kategori yang lebih cepat dari jadwal, baris per kategori (oranye ≥80%, merah >100%); pil bulan untuk melihat bulan lalu.
- [x] *(baru)* Layar Catat: kolom catatan menempel tepat di atas keypad (tidak ada jarak kosong besar).
- [x] *(baru)* Budget per bulan: ubah target di bulan ini → bulan lalu (pil bulan ‹) tetap memakai target lamanya; bulan depan ikut target baru.
- [x] *(baru)* Ikon di seluruh app sama dengan ikon garis di desain **dan tepat di tengah kotaknya** (navigasi bawah, kategori, dompet, menu Lainnya, tombol header).

- [ ] *(baru)* Catat pengeluaran melebihi saldo dompet (mis. saldo GoPay Rp20rb, catat Rp25rb) → sheet "Saldo GoPay jadi minus":
      **Tetap catat** → tersimpan; **Sesuaikan saldo** → isi saldo sebenarnya → tersimpan & saldo dompet = isian − nominal.
      Pindah saldo dari dompet yang kurang juga ditanya. Dompet yang sudah minus tidak ditanya lagi.
- [ ] *(baru)* Edit transaksi: Pengeluaran ↔ Pemasukan bisa diganti; tab **Pindah Saldo** redup → ketuk → snackbar penjelasan.
      Edit Pindah saldo / transaksi dari tagihan atau berulang: tab lain redup & tidak bisa dipilih.
- [x] *(P1)* **Jatah hari ini** di Beranda (di bawah Total saldo): angka = (saldo − tagihan & transaksi berulang sampai gajian) ÷ sisa hari,
      atau sisa budget bulan ini bila lebih kecil. Catat pengeluaran → jatah tetap, hanya "Sisa" yang turun; lewat → "Lewat … — jatah besok jadi …".
- [ ] *(P1)* Ketuk kartu → "Dari mana angka ini?" (rincian, hitungan pembanding) → Ubah tanggal gajian → pilih tanggal → angka & "gajian N hari lagi" berubah.
      Saran tanggal muncul bila ada transaksi berulang pemasukan berkategori Gaji.
- [ ] *(P1)* Dompet › Ubah dompet → matikan "Ikut dihitung di jatah harian" → dompet itu bertuliskan "tidak dihitung di jatah" dan saldonya tidak ikut jatah.
- [ ] *(P1)* Tombol mata menyamarkan jatah; besok (atau ubah tanggal HP) jatah dihitung ulang tanpa menutup aplikasi.
- [x] *(P1)* Catat cepat: "parkir seceng", "es teh goceng", "bakso ceban", "makan goban", "2 ceban", "sejuta", "setengah juta" → nominal benar;
      "kopi 25rb spay/gpay/livin/brimo" memilih dompet yang cocok (bila ada); "kopi 18rb pakai qris" tidak memilih dompet & "qris" tidak masuk catatan.
- [x] *(P1)* **Sekali ketuk**: catat transaksi yang sama (catatan, kategori, dompet, nominal) 3× → chip muncul di bawah Catat cepat.
      Ketuk chip → langsung tercatat hari ini + "… dicatat · Urungkan" (Urungkan menghapusnya). Tekan lama → Ubah dulu / Sembunyikan.
- [ ] *(P1)* Detail transaksi → **Jadikan favorit** → chip langsung muncul paling depan; ketuk lagi → dilepas. Pindah saldo tidak punya tombol ini.
- [x] *(P1)* **Widget**: tahan layar utama → Widget → HitungIn: "Jatah hari ini" (4×2) & "Catat" (2×1).
      Widget sedang menampilkan jatah, sisa, bar, dan 3 favorit; catat transaksi → widget berubah dalam beberapa detik.
      Tombol mata (sembunyikan saldo) → widget menampilkan Rp ••••. Besok sebelum aplikasi dibuka → "Buka HitungIn untuk memperbarui jatah".
- [x] *(P1)* Ketuk widget/favorit/tombol + saat aplikasi terkunci → PIN → langsung Catat (favorit: form terisi, tinggal Simpan); Back → Beranda.
- [x] *(P1)* **Tile Quick Settings**: edit panel Quick Settings → tambah "Catat · HitungIn" → ketuk → panel tertutup, layar Catat terbuka.
- [x] *(P1)* **Pintasan ikon**: tekan lama ikon HitungIn → Catat pengeluaran / Catat pemasukan (tab Pemasukan) / Pindah saldo / Riwayat.
      Ganti ikon alternatif (Pro) → pintasan tetap muncul di ikon yang baru (belum diuji: butuh Pro).
- [x] *(P1)* Widget/tile/pintasan saat aplikasi sedang terbuka → TIDAK membuat salinan kedua di Recents (satu task).
## 4. Lainnya (pengaturan)
- [x] Nama panggilan berubah di sapaan Beranda.
- [x] Dompet: tambah, urutkan (tahan & geser), arsipkan (hilang dari total), hapus dompet terpakai ditolak.
- [x] Kategori: tambah dengan kata kunci → langsung dikenali Catat cepat; arsipkan.
- [x] Tagihan: tambah, Bayar → tercatat & jatuh tempo maju; "Tagihan mendatang" di Beranda saat dekat/lewat.
- [x] Tema: mode gelap/terang/AMOLED/sistem & aksen berubah langsung dan bertahan setelah aplikasi dibuka ulang.
- [x] Ganti PIN: PIN lama salah ditolak; PIN baru berlaku setelah dikunci ulang.
- [x] *(baru)* Dompet: kartu Total saldo + **Pindah saldo** (buka Catat langsung di Pindah Saldo) + bar porsi saldo berwarna; grup **Tunai & bank / E-wallet** dengan inisial berwarna & jumlah transaksi bulan ini; ketuk dompet → ubah warna, **Saldo sekarang** (sesuaikan saldo), **Lihat riwayat** (Riwayat terfilter dompet itu).
- [x] *(baru)* Kategori: grid 2 kolom, **tahan & geser** untuk urutkan; form: ikon, **warna**, **sub-kategori** (tambah/hapus), kata kunci. Warna ikut di Beranda/Riwayat/Detail/Budget/donat Laporan.
- [x] *(baru)* Sub-kategori: di Catat muncul chip sub setelah pilih kategori; Catat cepat `makan siang 30rb` → Makan & Minum › Makan siang; Detail menampilkan "Makan & Minum › Kopi"; Riwayat bisa dicari dengan nama sub.
- [x] *(baru)* Tagihan: kartu **30 hari ke depan**, daftar **Akan datang** (chip jatuh tempo, dompet · ulang, **Tandai lunas**), **Sudah dicatat bulan ini** setelah melunasi; kartu Notifikasi pengingat (PRO) di bawah.
- [x] *(baru)* Setelah menyimpan transaksi lalu langsung membuka Catat lagi, tombol Simpan tidak tertutup snackbar.

- [ ] *(P1)* Kategori › ubah/baru → tab **Ikon** (30 ikon, termasuk peliharaan, bensin, parkir, arisan, cicilan, dll.) dan tab **Emoji**
      (40 pilihan + "Emoji lain" dari keyboard; huruf/angka ditolak). Emoji tampil di Beranda, Catat, Riwayat, Budget, Tagihan, favorit.
- [ ] *(P1)* Dompet › ubah → Tampilan **Inisial | Emoji** → daftar dompet & pilihan dompet di Catat memakai emoji itu.
- [ ] *(P1)* Backup → pulihkan di HP lain → emoji kategori & dompet tetap sama.
## 5. Cadangan & ekspor
- [x] Buat cadangan → simpan ke folder / Google Drive lewat pemilih berkas.
- [x] Hapus data aplikasi (Pengaturan Android) → onboarding lagi → Pulihkan dari cadangan: kata sandi salah ditolak;
      benar → ringkasan isi → semua data kembali (dompet, transaksi, budget, tagihan, jadwal berulang, tema).
- [x] Pulihkan di HP lain (pindah HP) bila memungkinkan.
- [x] CSV (gratis): tawaran iklan berhadiah → tonton sampai selesai → berkas tersimpan; buka di Excel/Sheets:
      huruf & nominal benar, catatan berisi `=` tidak dieksekusi.
- [x] *(baru)* Backup: kartu status (Belum ada backup / Data aman / Sudah lama tidak backup, kapan terakhir), progres saat mencadangkan, "Backup selesai · ukuran" lalu "Backup lagi"; baris Password (ditanya tiap backup), Lokasi, Backup otomatis (PRO · segera); tombol Pulihkan dari file & Export CSV; kotak peringatan kata sandi.
- [x] *(baru)* Dompet & Kategori: keterangan kecil menempel di bawah layar (bukan menempel ke kartu terakhir).
- [ ] *(baru)* Buat backup → muncul "Cadangan tersimpan" (berkas sudah diperiksa ulang dengan kata sandinya sebelum disimpan).
- [ ] *(baru)* Ganti HP: instal HitungIn di HP lain → Pulihkan dari berkas → Beranda menampilkan "backup <tanggal berkas>", bukan "belum ada backup";
      Pro aktif lagi otomatis bila akun Play sama.

## 6. Iklan (versi gratis)
- [x] Persetujuan iklan (UMP): **di Indonesia memang tidak muncul** — Google hanya menampilkannya di wilayah yang
      mewajibkan (EEA/UK/Swiss). Tidak muncul = normal; iklan tetap jalan (non-personal bila belum ada persetujuan).
      Menu "Privasi iklan" di Lainnya hanya tampil bila wilayahmu mewajibkannya.
- [x] *(ubah)* Banner hanya di **Beranda, Laporan, Budget** — **tidak** di Riwayat, Catat, kunci, Lainnya, Cadangan.
- [x] Banner tidak menutupi navigasi bawah & tidak ada kotak kosong saat iklan gagal dimuat (mode pesawat).
- [x] Mode pesawat: aplikasi tetap berfungsi penuh tanpa internet.

- [ ] *(baru)* Banner iklan tidak bersentuhan dengan tombol **+**: ada jarak kosong di antara banner dan bar navigasi.
## 6b. Navigasi (baru)
- [x] Tombol kembali HP di Laporan / Budget / Lainnya → pindah ke Beranda; di Beranda → keluar aplikasi.
      Di layar yang dibuka di atasnya (Riwayat, Detail, Dompet, dll.) kembali seperti biasa ke layar sebelumnya.
- [x] Riwayat bisa dibuka dari: "Lihat semua" (Beranda), kartu **Masuk/Keluar bulan ini** di Beranda (terfilter jenis),
      kartu **Pemasukan/Pengeluaran** di Laporan (bulan & jenis), legenda donat Laporan (kategori), baris kategori di
      **Budget** (kategori & bulan), **Dompet › Lihat riwayat**, dan menu **Lainnya › Riwayat transaksi**.
- [x] Backup: kotak peringatan kata sandi menempel di dasar layar.

## 7. Pro (setelah persiapan butir 0)
> **Uji fitur Pro lebih dulu tanpa Google Play:** pasang build debug (`flutter run`), buka **Lainnya › Mode Pro (uji)**
> dan nyalakan. Semua butir di bawah kecuali 3 butir pertama (beli, tertunda, pulihkan) bisa diuji dengan cara ini,
> begitu juga bagian 8. Matikan lagi untuk melihat batas versi gratis. Sakelar ini tidak ada di build rilis.

- [x] Beli Pro (Pengujian internal, penguji lisensi) → dialog Google Play → sukses → banner hilang, batas gratis hilang, "HitungIn Pro aktif".
- [ ] Bayar tertunda (metode "lambat" kartu uji) → "Menunggu pembayaran" → aktif otomatis setelah selesai.
- [ ] Hapus & pasang ulang aplikasi → "Pulihkan pembelian" → Pro aktif lagi.
- [ ] *(baru)* Hapus & pasang ulang → buka aplikasi (tanpa menekan apa pun) → Pro aktif sendiri setelah Play terhubung.
- [ ] *(baru)* Refund pesanan uji di Play Console (Pengelolaan pesanan → Refund, centang **cabut hak**) → tutup & buka
      aplikasi → Pro dicabut, iklan kembali, layar Pro menampilkan "tidak lagi tercatat di Google Play".
      Catatan: bisa butuh beberapa menit sampai cache Play Store di HP diperbarui.
- [ ] *(baru)* Mode pesawat → buka aplikasi → status Pro **tidak** berubah.
- [ ] *(baru)* Akun tanpa pembelian → "Pulihkan pembelian" → pesan "Belum ada pembelian HitungIn Pro di akun Google Play ini".
- [x] Laporan: filter dompet, tren 6/12 bulan.
- [x] Transaksi berulang: jadwal mulai hari ini → langsung tercatat; ubah tanggal HP ke bulan depan → buka
      aplikasi → masukkan PIN → tercatat susulan + snackbar **setelah** layar kunci terbuka.
- [ ] Aksen Pro (Plum, Laut, Kopi, Arang).
- [ ] *(baru)* Bulan berganti saat app terbuka/di latar (mis. lewat tengah malam akhir bulan, atau tanggal HP diubah):
      Riwayat, Laporan, Budget, Beranda pindah ke bulan baru tanpa menutup app.
- [x] **Ikon alternatif** Gelap/Emas/Terang (diuji via ADB di Samsung A52, mode gelap): pilih → snackbar "Ikon berganti setelah kamu keluar" → aplikasi
      **tidak** tertutup; tekan Home → ikon di launcher berganti (bisa butuh beberapa detik); buka lagi dari ikon baru
      tanpa crash (juga saat mode gelap HP aktif),
      aplikasi tetap bisa dibuka dari ikon baru, tidak ada ikon dobel. Uji di launcher bawaan HP & bila ada,
      launcher lain (Nova, Samsung One UI, MIUI/HyperOS).
      Catatan debug: selama ikon alternatif aktif, setelah "Installing…" di VS Code buka HitungIn dari ikonnya di HP
      supaya debugger tersambung (lihat README).
- [ ] Android 13+: ikon bertema (wallpaper → "Ikon bertema") memakai logo monokrom.

## 8. Notifikasi tagihan (Pro)
> Build debug: kartu "Notifikasi pengingat" di Tagihan punya tombol **Uji notifikasi** — "Kirim sekarang"
> (isi sama dengan pengingat asli tagihan pertama) dan "1 menit lagi" (terjadwal; tekan lalu keluar ke Home).
> Jadwal asli memakai alarm tidak-tepat (bisa mundur sampai ±1 jam bila HP hemat baterai).
- [x] Nyalakan pengingat → dialog izin notifikasi (Android 13+).
- [x] Tagihan jatuh tempo besok + jam pengingat beberapa menit lagi → **tutup aplikasi** → notifikasi muncul
      (boleh meleset beberapa menit).
- [x] Notifikasi tetap ada di panel sampai diketuk / tagihan dibayar (tidak hilang sendiri saat aplikasi dibuka).
- [x] Layar kunci aman: isi notifikasi tersembunyi.
- [x] Ketuk notifikasi saat aplikasi terkunci → minta PIN → layar Tagihan; Back → Beranda.
- [x] Restart HP sebelum waktu pengingat → notifikasi tetap muncul.
- [x] Bayar tagihan → notifikasi lama tidak muncul lagi; jadwal pindah ke jatuh tempo berikutnya.
- [x] Matikan izin notifikasi dari pengaturan HP → kartu Tagihan menampilkan peringatan + tombol Izinkan.

## 9. Umum
- [x] Ukuran huruf sistem besar (Pengaturan → Tampilan) → tidak ada teks terpotong parah / tombol tertutup.
- [x] TalkBack: tombol keypad PIN, tab bawah, dan baris transaksi terbaca dengan jelas.
- [x] "Kurangi animasi" aktif → animasi (splash, angka, progress) mati.
- [x] Rotasi: tetap potret.
- [x] Gestur kembali Android (predictive back) wajar di semua layar.

## 10. Cicilan & utang-piutang (P2, baru)
Pasang di atas versi lama (jangan uninstall) supaya migrasi skema v4 → v5 ikut teruji.
- [x] Setelah update: dompet, transaksi, tagihan lama tetap utuh.
- [x] Tagihan → + Tambah → chip "SPayLater" → saklar Cicilan menyala; atur tenor 12, sudah dibayar 3 → baris "Cicilan 4/12 · sisa … · lunas …" + bar progres.
- [x] "Bayar 4/12" → tercatat pengeluaran "SPayLater · cicilan 4/12" (kategori Tagihan bila kosong), hitungan naik.
- [x] Cicilan terakhir → muncul "… lunas!", tagihan hilang dari Akan datang, tidak ada pengingat lagi.
- [ ] Ringkasan "Sisa cicilan Rp… · N berjalan" di Tagihan dan Beranda (Beranda: tersamar saat saldo disembunyikan).
- [ ] Versi gratis: cicilan ikut batas 3 tagihan aktif.
- [x] Lainnya › Utang-piutang → + Catat "Aku meminjamkan" Budi Rp200.000 dari Tunai → saldo Tunai turun, Laporan pengeluaran tidak berubah, Riwayat menampilkan "Dipinjamkan ke Budi".
- [x] Catat pembayaran Rp100.000 → status Dicicil + bar; bayar lagi Rp100.000 → "Budi lunas!", status Lunas.
- [x] Jatuh tempo lewat → chip "Lewat jatuh tempo" + hitungan di kartu ringkasan.
- [x] Tagih lewat WhatsApp → teks bisa diubah → menu Bagikan → WhatsApp; kembali ke HitungIn tidak minta PIN lagi.
- [x] Utangku dengan jatuh tempo sebelum gajian → Jatah hari ini turun; rinciannya ada baris "Utang jatuh tempo".
- [x] Catat cepat di Beranda: "pinjam budi 200rb" → form Utang-piutang terisi; "budi bayar 100rb" → sheet pembayaran Budi; "pinjam dari sinta 300rb" → arah Aku meminjam.
- [x] Ketik "pinjam budi" di kolom Catat cepat layar Catat → muncul ajakan "Utang-piutang: … Buka ›".
- [x] Detail transaksi utang → tanpa Edit/Hapus, tombol "Buka Utang-piutang".
- [x] Hapus catatan utang → saldo dompet kembali seperti semula.
- [ ] Backup → pulihkan: catatan utang, pembayaran, dan cicilan kembali utuh.
- [x] (Pro) Utang/piutang dengan jatuh tempo besok → notifikasi H-1 & hari H pada jam pengingat ("Utang ke …" / "Waktunya menagih …"); ketuk saat terkunci → PIN → detail catatan itu.
- [x] Catatan dilunasi → notifikasinya yang sudah tampil ikut hilang; versi gratis: form menampilkan lencana PRO, tanpa notifikasi.

## 11. Personalisasi (P2b, baru)
- [ ] Pasang widget Jatah 4×2 → HitungIn terbuka di "Atur widget" (lewat PIN bila terkunci); widget langsung tampil dengan gaya "Ikut tema".
- [x] Latar Aksen / Gradien (Senja, Laut, Lembut) / transparansi / sudut / warna teks → Simpan → widget di layar utama berubah sama seperti pratinjau.
- [x] (Pro) Latar Foto: pilih foto → atur posisi & lapisan → angka tetap terbaca di foto terang dan gelap. Versi gratis: pilihan Foto membuka layar Pro.
- [ ] Pasang dua widget Jatah, beri gaya berbeda → keduanya tampil beda dan sama-sama terbarui setelah transaksi disimpan.
- [ ] "Samarkan angka di widget ini" → hanya widget itu yang Rp ••••.
- [x] Tekan lama widget › Atur ulang (Android 12+) → kembali ke Atur widget untuk widget itu.
- [ ] Lepas widget berfoto → buka Atur widget → fotonya ikut terhapus (tidak tersisa di penyimpanan).
- [ ] Backup → pulihkan: gaya widget kembali, widget berfoto jadi "Ikut tema".
- [x] Tema › Wallpaper (Android 12+): aksen mengikuti wallpaper; ganti wallpaper → kembali ke HitungIn → aksen ikut berubah.
- [ ] (Pro) Warna bebas: warna terlalu terang diberi keterangan & digelapkan; (Pro) Dari foto: 2–4 warna muncul, ketuk → aksen berubah.
- [x] Gaya ikon Garis / Isi / (Pro) Duotone / (Pro) Bulat → semua layar (Beranda, Catat, Riwayat, Laporan, Budget, Lainnya) langsung berganti tanpa restart.
- [x] Wadah ikon Kotak / Lingkaran / Tanpa; tombol Catat Kotak / Bulat / "+ Catat"; ikon tombol +, pensil, koin; label tab disembunyikan.
- [x] Notifikasi & widget ikut warna aksen yang dipilih.
- [x] (Pro) Atur Beranda: seret kartu, sembunyikan kartu, "Bawaan" → Beranda mengikuti; versi gratis tetap susunan bawaan.

## 12. Rekap mingguan & streak (P3a, baru)
- [x] Senin–Rabu: kartu "Rekap minggu lalu" di Beranda; ✕ menutupnya sampai minggu berikutnya.
- [x] Catat transaksi → chip "🔥 N hari" muncul di samping tanggal.
- [x] Layar Rekap: pindah minggu, label "minggu ini/itu", per hari, kategori terbesar, insight, streak minggu berjalan.
- [x] Notifikasi rekap terjadwal Senin 08.00 (bawaan menyala).
- [x] Bagikan kartu (tanpa nominal) → menu Bagikan berisi 1 gambar; kembali tanpa PIN; berkas sementara terhapus.
- [ ] Senin pukul 08.00 notifikasi "Rekap minggumu sudah siap" muncul; ketuk → rekap minggu lalu.
- [ ] Pengingat malam dinyalakan + streak ≥ 3 + belum mencatat → notifikasi 20.00; setelah mencatat, notifikasinya hilang.
- [ ] Satu hari kosong dalam seminggu tidak memutus streak (☕ di lingkaran hari).
- [ ] Kartu dengan "Tampilkan nominal" menyala memuat angka rupiah; mati → tidak ada rupiah sama sekali.

## 13. Target tabungan (P3b, baru)
- [x] Pasang ulang di atas versi lama: migrasi v5 → v6, data lama utuh.
- [x] Lainnya › Target tabungan: tampilan kosong → "Buat target pertama" → form (ikon, nama, nominal, tanggal opsional, petunjuk per minggu).
- [x] Setoran dari dompet yang dihitung Jatah: terkumpul naik, Jatah hari ini turun, rincian Jatah memuat "Disisihkan untuk target"; saldo dompet & Laporan tidak berubah.
- [x] Lewat 25/50/75% → snackbar penyemangat; mencapai 100% → layar Target tercapai (konfeti, durasi, jumlah setoran).
- [x] Bagikan pencapaian: kartu tanpa nominal bawaan → menu Bagikan berisi 1 gambar; kembali tanpa PIN.
- [x] "Buat target baru" dari layar perayaan langsung membuka form.
- [x] Arsipkan target → pindah ke Diarsipkan, total disisihkan & Jatah dilepas.
- [x] Kartu kecil Target tabungan di Beranda (ikut Atur Beranda).
- [x] Pengingat setoran mingguan (bawaan mati) terjadwal & terkirim pada hari/jam pilihan (Selasa 17.00, terkirim 17.04).
- [ ] Ketuk notifikasi pengingat setoran → detail target.
- [x] Catat cepat "nabung 100rb bali" → lembar setoran Liburan Bali terisi, dompet otomatis terpilih.
- [x] Ambil: kembali jadi uang bebas; tidak bisa melebihi terkumpul. Tahan riwayat → hapus setoran.
- [ ] Versi gratis: target aktif kedua → lembar Premium.
- [ ] Backup & pulihkan membawa target dan setorannya.

## 14. Patungan (P3c, baru)
- [x] Pasang di atas versi lama: migrasi v6 → v7, data lama utuh.
- [x] Lainnya › Patungan: tampilan kosong → Buat patungan; Catat › "Bayar bareng teman? Patungan ›" membuka form.
- [x] Rata 4 orang Rp450.000, aku yang bayar: pengeluaran Rp112.500 di Laporan, 3 piutang di Utang-piutang, saldo −Rp450.000.
- [x] Teman yang bayar: pengeluaran bagianku + utangku ke dia, saldo tidak berubah.
- [x] Custom: Simpan ditolak bila sisa ≠ Rp0.
- [x] Per menu: tambah item (jumlah ×n), ketuk inisial untuk pilih siapa ikut, PB1/service/ongkir/diskon; jumlah bagian = total.
- [x] Detail: Tandai lunas → status "n/3 sudah bayar"; semua lunas → perayaan.
- [x] Bagikan ke grup: gambar + teks / gambar / teks; info transfer diingat; kembali tanpa PIN.
- [x] Ubah patungan sebelum ada pembayaran; setelah ada pembayaran ditolak dengan pesan.
- [x] Hapus patungan: saldo kembali, piutang & pengeluaran ikut hilang.
- [x] Detail transaksi bagianku: "bagianmu di patungan" + tombol Buka Patungan, tidak bisa diedit langsung.
- [ ] Backup & pulihkan membawa patungan.

## 15. Rapor bulanan (P3d, baru)
- [x] Pasang di atas versi lama: migrasi v7 → v8, data lama utuh.
- [x] Belum ada bulan selesai → "Rapor pertamamu terbit 1 November".
- [x] Laporan › Rapor bulanan dan Lainnya › Rapor bulanan menampilkan nilai bulan lalu (👌 Aman ●●●○).
- [x] Data minim: peringatan "datanya belum lengkap", Kata HitungIn mengajak mencatat, aspek tanpa data "❔ Belum dinilai".
- [x] Ketuk aspek → "Dari mana nilai ini?": rumus, angkamu, 4 batas (posisi disorot), dasar acuan, saran.
- [x] Ringkasan masuk/keluar/sisa, kategori terbesar, sorotan, saran bulan ini dengan tombol aksi.
- [x] Bagikan rapor: kartu tanpa nominal bawaan; "Tampilkan nominal" menambah baris sisa; menu Bagikan berisi 1 gambar.
- [x] Arsip: grafik nilai & daftar bulan.
- [x] Notifikasi rapor terjadwal tanggal 1 pukul 08.00.
- [ ] Tanggal 1–5: kartu "Rapor … terbit" di Beranda; ✕ menutupnya sampai bulan depan.
- [ ] Notifikasi tanggal 1 muncul; ketuk → layar Rapor.
- [ ] Bayar tagihan telat → bulan berikutnya aspek Tagihan tidak Juara.
- [ ] Budget total diatur & belanja cepat → kartu Prakiraan di Beranda & Budget.

## 16. Scan struk (P3e, baru)
- [x] Catat › ikon scan di Catat cepat → lembar Pindai/Galeri, lencana "offline, foto dihapus", sisa kuota (gratis).
- [x] Galeri › struk Indomaret uji → "Membaca struk…" → Periksa: Rp87.400, Indomaret, 18 Okt 19.42 (Cek lagi), GoPay, Belanja; "7 item cocok". (OCR nyata: spasi di tanggal & O→0 ditangani.)
- [x] Pakai → Catat terisi (nominal, catatan, tanggal, dompet, kategori); simpan normal.
- [x] Patungan › Per menu › Scan struk resto uji → 6 item, PB1 10%, Service 5%, QRIS; Pakai 6 item → item & chip terisi, total Rp411.700.
- [ ] Ketuk item di layar periksa → ubah; tahan → hapus.
- [x] Pindai: pemindai dokumen ML Kit (Google Play Services) terbuka, potong otomatis; batal → kembali tanpa error.
- [x] Pindai tidak tersedia → cadangan kamera bawaan terbuka.
- [x] Struk nyata POS resto: nama toko tidak tertukar teks logo, nama item beberapa baris, "7x @harga", item cocok total.
- [x] Tidak ada foto tertinggal di cache aplikasi (image_picker, pemindai, file_picker) setelah scan / batal / pilih file.
- [ ] Versi gratis: scan ke-4 dalam sebulan → lembar "Jatah scan gratis bulan ini habis".
- [x] Beranda › Ketik cepat kosong: satu tombol berikon struk → Catat terbuka & lembar Pindai/Galeri langsung muncul; mulai mengetik → tombol berubah jadi →, hapus teks → kembali ikon struk.
- [x] Catat › pil "Scan" di header kanan (judul tetap di tengah), kolom Catat cepat tanpa tombol; tidak tampil saat ubah transaksi.
- [x] Kartu "BARU · Foto struk, langsung tercatat" di bawah Ketik cepat; ✕ → hilang & tidak muncul lagi setelah buka ulang. (Coba scan / scan berhasil juga menutupnya.)
- [x] Pintasan ikon: Catat pengeluaran, Scan struk, Catat pemasukan, Pindah saldo (Riwayat dikeluarkan); Scan struk dari aplikasi tertutup → PIN → lembar scan langsung muncul.
- [ ] Tahan ikon HitungIn di layar utama → 4 pintasan dengan ikon Scan struk tampil benar.

## 17. Template budget (P3f, baru)
- [ ] Budget kosong › "Pakai template" → layar Template budget; 50/30/20 · 40/30/20/10 · Sendiri berganti dengan jatah per kelompok.
- [x] Pemasukan bulanan terisi dari rata-rata 3 bulan.
- [ ] Pemasukan −/+ Rp500rb menghitung ulang semua kelompok.
- [x] Ketuk kategori → pindah kelompok; pilihan tetap sama saat layar dibuka lagi.
- [x] Sendiri: −/+ 5% per kelompok, "Total 100% · Pas" / "Kurang/Lebih"; tombol simpan terkunci bila bukan 100%.
- [x] Tabungan: saran setoran per target aktif (tanpa target → ajakan membuat target).
- [x] Pro: "Lanjut ke Atur budget" → total & semua kategori terisi, catatan "Diisi dari template…"; simpan → kembali ke Budget.
- [ ] Gratis: catatan versi gratis; "Simpan versi gratis" → total + 2 kategori terbesar; tombol emas → Premium.
- [x] Atur budget › kartu "Pakai template" → Template budget.
- [x] Target tabungan: kartu "Saran setoran bulan ini dari template budget…".
- [x] Tanggal 1–5: kartu "Sisa budget <bulan lalu>" di Budget → lembar (di atas navigasi) Bawa / Setor ke target / Hangus (+ "… semua"), pilihan awal Setor bila ada target; simpan → batas kategori naik, **total tetap**, setoran masuk target, kartu hilang.
- [x] Sesudah sisa dibawa: catatan "Batas kategori bulan ini lebih Rp… dari total… Total tetap jadi batas utama."
- [x] Kategori lewat batas (bulan berjalan): tawaran "Ambil Rp… dari <kategori>"; Ambil → batas bergeser bulan itu saja; Urungkan mengembalikan.
- [ ] "Kategori lain" mengganti sumber (muncul bila ada ≥ 2 kategori sumber).
- [x] Kelompok tanpa kategori (mis. Cicilan di kategori bawaan): petunjuk "Belum ada kategori di sini", jatah tetap masuk total.
- [x] Debug: Lainnya › Isi data uji, Lompat ke tanggal 1 bulan depan (bisa berulang) & Kembali ke hari ini (jam aplikasi saja).
