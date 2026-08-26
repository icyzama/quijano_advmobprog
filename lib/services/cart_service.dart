import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';

class CartService {
  // Enhancement 3: Load one user's cart using DummyJSON's user-cart endpoint.
  Future<Cart> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final carts = data['carts'] as List? ?? [];
      if (carts.isEmpty) {
        throw Exception('No cart found for this user');
      }
      return Cart.fromJson(carts.first as Map<String, dynamic>);
    }
    throw Exception('Failed to load cart');
  }

  // Enhancement 3: Send a product and quantity to DummyJSON's add-cart API.
  Future<void> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add product to cart');
    }
  }
}
