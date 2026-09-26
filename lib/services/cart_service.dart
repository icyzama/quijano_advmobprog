import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';

class CartService {
  // DummyJSON returns a list for this endpoint; the app displays one user's first cart.
  Future<Cart> getCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final carts = data['carts'] as List? ?? [];
      if (carts.isEmpty) {
        return Cart.emptyForUser(userId);
      }
      return Cart.fromJson(carts.first as Map<String, dynamic>);
    }
    throw Exception('Failed to load cart');
  }

  Future<Cart> addToCart({
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

    return Cart.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
