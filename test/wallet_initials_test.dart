import 'package:flutter_test/flutter_test.dart';
import 'package:hitungin/core/db/app_database.dart';
import 'package:hitungin/features/wallets/wallets_screen.dart';

Wallet _w(String name, WalletType type) => Wallet(
      id: 1,
      name: name,
      type: type,
      initialBalance: 0,
      icon: 'wallet',
      color: 0,
      sortOrder: 0,
      archived: false,
      createdAt: DateTime(2026),
    );

void main() {
  test('inisial dompet seperti desain', () {
    expect(walletInitials(_w('Tunai', WalletType.tunai)), 'Rp');
    expect(walletInitials(_w('BCA', WalletType.bank)), 'BC');
    expect(walletInitials(_w('GoPay', WalletType.ewallet)), 'GP');
    expect(walletInitials(_w('Bank Jago', WalletType.bank)), 'BJ');
    expect(walletInitials(_w('mandiri', WalletType.bank)), 'MA');
  });
}
