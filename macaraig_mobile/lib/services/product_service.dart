import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/product.dart';

class ProductService {
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$host/products'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List productsJson = data['products'] ?? [];
      return productsJson
          .map((json) => Product.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Enhancement 1: needed so cart_screen.dart can resolve a full Product
  // (with description, category, reviews, etc.) from a tapped CartProduct,
  // which only carries a subset of fields, before pushing to detail_screen.
  Future<Product> getProductById(int id) async {
    final response = await http.get(Uri.parse('$host/products/$id'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Product.fromJson(data);
    } else {
      throw Exception('Failed to load product');
    }
  }
}