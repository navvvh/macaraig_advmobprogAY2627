import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/user.dart' as app;

class CartService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;

  /// Firebase accounts have no DummyJSON numeric user ID, so their carts are
  /// kept separately per Firebase UID on this device.
  Future<List<Cart>> getCartForUser(app.User user) async {
    if (user.loginType == 'firebase') return _getFirebaseCart();
    return getCartByUserId(user.id);
  }

  Future<Cart> addProductForUser(app.User user, Product product) async {
    if (user.loginType == 'firebase') return _addFirebaseProduct(product);
    if (user.id <= 0) throw Exception('No valid DummyJSON user is signed in.');
    return addToCart(
      userId: user.id,
      products: [{'id': product.id, 'quantity': 1}],
    );
  }

  Future<void> saveFirebaseCartQuantities(Map<int, int> quantities) async {
    final cart = await _getFirebaseCart();
    if (cart.isEmpty) return;
    final products = cart.first.products.map((product) {
      final quantity = quantities[product.id] ?? product.quantity;
      return _withQuantity(product, quantity);
    }).toList();
    await _saveFirebaseProducts(products);
  }

  String get _firebaseCartKey {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Please sign in to access your cart.');
    }
    return 'firebase_cart_$uid';
  }

  Future<List<Cart>> _getFirebaseCart() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_firebaseCartKey);
    if (encoded == null || encoded.isEmpty) return [];
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      final products = decoded
          .map((item) => CartProduct.fromJson(item as Map<String, dynamic>))
          .toList();
      if (products.isEmpty) return [];
      return [_buildFirebaseCart(products)];
    } on FormatException {
      await prefs.remove(_firebaseCartKey);
      return [];
    }
  }

  Future<Cart> _addFirebaseProduct(Product product) async {
    final current = await _getFirebaseCart();
    final products = current.isEmpty ? <CartProduct>[] : current.first.products;
    final existingIndex = products.indexWhere((item) => item.id == product.id);
    if (existingIndex >= 0) {
      final existing = products[existingIndex];
      products[existingIndex] = _withQuantity(existing, existing.quantity + 1);
    } else {
      products.add(CartProduct(
        id: product.id,
        title: product.title,
        price: product.price,
        quantity: 1,
        total: product.price,
        discountPercentage: product.discountPercentage,
        discountedTotal: product.price * (1 - product.discountPercentage / 100),
        thumbnail: product.thumbnail,
      ));
    }
    await _saveFirebaseProducts(products);
    return _buildFirebaseCart(products);
  }

  Future<void> _saveFirebaseProducts(List<CartProduct> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _firebaseCartKey,
      jsonEncode(products.map((product) => product.toJson()).toList()),
    );
  }

  CartProduct _withQuantity(CartProduct product, int quantity) {
    final total = product.price * quantity;
    return CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: quantity,
      total: total,
      discountPercentage: product.discountPercentage,
      discountedTotal: total * (1 - product.discountPercentage / 100),
      thumbnail: product.thumbnail,
    );
  }

  Cart _buildFirebaseCart(List<CartProduct> products) {
    final total = products.fold<double>(0, (sum, item) => sum + item.total);
    final discountedTotal = products.fold<double>(
      0,
      (sum, item) => sum + item.discountedTotal,
    );
    return Cart(
      id: 0,
      products: List<CartProduct>.from(products),
      total: total,
      discountedTotal: discountedTotal,
      userId: 0,
      totalProducts: products.length,
      totalQuantity: products.fold<int>(0, (sum, item) => sum + item.quantity),
    );
  }

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
