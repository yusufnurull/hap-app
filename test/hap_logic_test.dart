import 'package:flutter_test/flutter_test.dart';

import 'package:hap/core/utils/formatters.dart';
import 'package:hap/core/utils/hap_logic.dart';
import 'package:hap/data/mock_data.dart';
import 'package:hap/providers/cart_provider.dart';

void main() {
  test('formatRupiah memakai titik ribuan', () {
    expect(formatRupiah(12000), 'Rp12.000');
    expect(formatRupiah(214000), 'Rp214.000');
  });

  test('keranjang hanya boleh satu stand', () {
    final cart = initialCart; // bu-sri
    expect(canAddDirectlyToCart(cart, 'bu-sri'), isTrue);
    expect(canAddDirectlyToCart(cart, 'mas-joko'), isFalse);
  });

  test('jumlah di keranjang dibatasi stok', () {
    final geprek = mockMenus.firstWhere((m) => m.id == 'ayam-geprek'); // stok 3
    final cart = addItemToCart(CartState.empty, geprek, qtyToAdd: 10);
    expect(cart.items['ayam-geprek'], 3);
  });

  test('adjustCartToStock membuang menu habis', () {
    final menus = setMenuStock(mockMenus, 'ayam-geprek', 0);
    final result = adjustCartToStock(initialCart, menus);
    expect(result.changed, isTrue);
    expect(result.cart.items.containsKey('ayam-geprek'), isFalse);
  });

  test('pesanan siap lewat 30 menit dianggap overdue', () {
    expect(isPickupOverdue('11.15', nowTime: '11.55'), isTrue);
    expect(isPickupOverdue('11.40', nowTime: '11.55'), isFalse);
  });
}
