import 'package:drift/drift.dart';

import 'app_database.dart';

/// Kategori bawaan saat database pertama kali dibuat. Pengguna bisa
/// mengubah, menambah, atau mengarsipkannya nanti.
///
/// Kata kunci dipakai Catat Cepat ("kopi 25rb gopay" → Makan & Minum).
const List<(String name, TxKind kind, String icon, String keywords)> defaultCategories = [
  ('Makan & Minum', TxKind.pengeluaran, 'food',
      'makan,minum,kopi,ngopi,nasi,bakso,mie,sate,ayam,jajan,snack,sarapan,siang,malam,gofood,grabfood,shopeefood,warteg,resto,cafe,teh,boba,roti,lunch,dinner'),
  ('Transportasi', TxKind.pengeluaran, 'transport',
      'bensin,pertalite,pertamax,parkir,tol,ojek,ojol,gojek,goride,grab,grabbike,grabcar,gocar,taksi,bus,krl,mrt,lrt,kereta,transjakarta,angkot,servis,motor,mobil'),
  ('Belanja', TxKind.pengeluaran, 'shopping',
      'belanja,shopee,tokopedia,lazada,tiktokshop,baju,sepatu,indomaret,alfamart,supermarket,minimarket,sabun,sampo,skincare'),
  ('Tagihan', TxKind.pengeluaran, 'bills',
      'listrik,pln,token,air,pdam,internet,wifi,indihome,pulsa,kuota,paket,bpjs,cicilan,kredit,asuransi,langganan,netflix,spotify,youtube'),
  ('Rumah', TxKind.pengeluaran, 'home', 'kos,kost,sewa,kontrakan,gas,galon,laundry,perabot,iuran'),
  ('Hiburan', TxKind.pengeluaran, 'fun', 'nonton,bioskop,film,game,konser,liburan,jalan,hotel,tiket,karaoke'),
  ('Kesehatan', TxKind.pengeluaran, 'health', 'obat,dokter,apotek,klinik,rs,vitamin,gym,periksa'),
  ('Pendidikan', TxKind.pengeluaran, 'education', 'buku,kursus,les,sekolah,kuliah,ukt,spp,seminar,kelas'),
  ('Sosial', TxKind.pengeluaran, 'gift', 'kado,sumbangan,donasi,zakat,infaq,sedekah,arisan,kondangan,traktir'),
  ('Lainnya', TxKind.pengeluaran, 'other', ''),
  ('Gaji', TxKind.pemasukan, 'salary', 'gaji,gajian,salary,upah,honor'),
  ('Bonus', TxKind.pemasukan, 'bonus', 'bonus,thr,insentif,komisi'),
  ('Usaha', TxKind.pemasukan, 'business', 'jualan,jual,penjualan,omzet,usaha,freelance,proyek,project'),
  ('Hadiah', TxKind.pemasukan, 'gift', 'hadiah,angpao,angpau,dikasih,kiriman'),
  ('Investasi', TxKind.pemasukan, 'invest', 'dividen,bunga,return,profit,saham,reksadana'),
  ('Lainnya', TxKind.pemasukan, 'other', 'refund,cashback,kembalian'),
];

/// Warna (indeks `AppPalette`) & sub-kategori bawaan, per (nama, jenis). v4.
const Map<(String, TxKind), (int color, String subs)> defaultCategoryStyle = {
  ('Makan & Minum', TxKind.pengeluaran): (0, 'Kopi,Makan siang,Jajan'),
  ('Transportasi', TxKind.pengeluaran): (3, 'Ojol,Bensin,Parkir'),
  ('Belanja', TxKind.pengeluaran): (4, 'Bulanan,Online'),
  ('Tagihan', TxKind.pengeluaran): (1, 'Listrik,Internet,Pulsa,BPJS'),
  ('Rumah', TxKind.pengeluaran): (2, ''),
  ('Hiburan', TxKind.pengeluaran): (6, 'Streaming,Nonton'),
  ('Kesehatan', TxKind.pengeluaran): (5, ''),
  ('Pendidikan', TxKind.pengeluaran): (3, ''),
  ('Sosial', TxKind.pengeluaran): (4, ''),
  ('Lainnya', TxKind.pengeluaran): (7, ''),
  ('Gaji', TxKind.pemasukan): (5, ''),
  ('Bonus', TxKind.pemasukan): (1, ''),
  ('Usaha', TxKind.pemasukan): (2, ''),
  ('Hadiah', TxKind.pemasukan): (4, ''),
  ('Investasi', TxKind.pemasukan): (3, ''),
  ('Lainnya', TxKind.pemasukan): (7, ''),
};

/// Warna dompet bawaan menurut urutan (aksen, teal, amber, lavender, …).
const List<int> walletColorCycle = [0, 2, 1, 6, 3, 4, 5, 7];

Future<void> seedDefaults(AppDatabase db) async {
  await db.batch((b) {
    for (final (int i, (String name, TxKind kind, String icon, String keywords)) in defaultCategories.indexed) {
      final (int color, String subs) = defaultCategoryStyle[(name, kind)] ?? (0, '');
      b.insert(
        db.categories,
        CategoriesCompanion.insert(
          name: name,
          kind: kind,
          icon: Value(icon),
          keywords: Value(keywords),
          color: Value(color),
          subs: Value(subs),
          sortOrder: Value(i),
        ),
      );
    }
  });
}

/// v3 → v4: warna & sub-kategori untuk kategori bawaan yang masih ada,
/// warna dompet menurut urutan.
Future<void> applyDefaultStyles(AppDatabase db) async {
  for (final MapEntry<(String, TxKind), (int, String)> e in defaultCategoryStyle.entries) {
    await (db.update(db.categories)..where((c) => c.name.equals(e.key.$1) & c.kind.equalsValue(e.key.$2)))
        .write(CategoriesCompanion(color: Value(e.value.$1), subs: Value(e.value.$2)));
  }
  final List<Wallet> wallets = await (db.select(db.wallets)..orderBy([(w) => OrderingTerm(expression: w.sortOrder)])).get();
  for (final (int i, Wallet w) in wallets.indexed) {
    await (db.update(db.wallets)..where((x) => x.id.equals(w.id)))
        .write(WalletsCompanion(color: Value(walletColorCycle[i % walletColorCycle.length])));
  }
}
