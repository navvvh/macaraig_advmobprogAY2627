import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService {
  // Enhancement 1: Gets all carts from the DummyJSON Cart API.
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];

      return cartsJson
          .map((json) => Cart.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // Enhancement 3: Gets the cart belonging to a specific user.
  Future<List<Cart>> getCartByUserId(int userId) async {
    final response = await http.get(
      Uri.parse('$host/carts/user/$userId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];

      return cartsJson
          .map((json) => Cart.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load user cart');
    }
  }

  // Enhancement 3: Adds products to a user's cart using the
  // DummyJSON Add to Cart endpoint.
  Future<Cart> addToCart({
    required int userId,
    required List<Map<String, int>> products,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'products': products,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Cart.fromJson(data);
    } else {
      throw Exception('Failed to add products to cart');
    }
  }
}