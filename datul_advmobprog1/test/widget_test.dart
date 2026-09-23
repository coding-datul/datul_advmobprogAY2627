import 'package:flutter_test/flutter_test.dart';
import 'package:datul_advmobprog1/models/cart.dart';

void main() {
  test('Cart model deserialization test', () {
    final mockJson = {
      'id': 1,
      'products': [
        {
          'id': 101,
          'title': 'Test Item',
          'price': 25.0,
          'quantity': 2,
          'total': 50.0,
          'discountPercentage': 10.0,
          'discountedTotal': 45.0,
          'thumbnail': 'https://example.com/test.jpg',
        }
      ],
      'total': 50.0,
      'discountedTotal': 45.0,
      'userId': 5,
      'totalProducts': 1,
      'totalQuantity': 2,
    };

    final cart = Cart.fromJson(mockJson);

    expect(cart.id, 1);
    expect(cart.userId, 5);
    expect(cart.products.length, 1);
    expect(cart.products.first.title, 'Test Item');
    expect(cart.products.first.price, 25.0);
    expect(cart.discountedTotal, 45.0);
  });
}
