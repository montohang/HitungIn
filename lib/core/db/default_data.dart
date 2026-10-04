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

Future<void> seedDefaults(AppDatabase db) async {
  await db.batch((b) {
    for (final (int i, (String name, TxKind kind, String icon, String keywords)) in defaultCategories.indexed) {
      b.insert(
        db.categories,
        CategoriesCompanion.insert(
          name: name,
          kind: kind,
          icon: Value(icon),
          keywords: Value(keywords),
          sortOrder: Value(i),
        ),
      );
    }
  });
}
