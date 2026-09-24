import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService {
  static final Map<int, Map<int, CartProduct>> _sessionCartProductsByUser = {};

  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  Future<Cart?> getCartByUserId(int userId) async {
    try {
      final response = await http.get(Uri.parse('$host/carts/user/$userId'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List cartsJson = data['carts'] ?? [];

        if (cartsJson.isNotEmpty) {
          return Cart.fromJson(cartsJson.first);
        }
      }
    } catch (_) {
      // Fallback to the app session cart if the user cart endpoint is unavailable.
    }

    final sessionCart = _buildSessionCart(userId);
    return sessionCart != null && sessionCart.products.isNotEmpty ? sessionCart : null;
  }

  Future<Cart?> getSeededCartByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      if (cartsJson.isEmpty) {
        return null;
      }
      return Cart.fromJson(cartsJson.first);
    } else {
      throw Exception('Failed to load user cart');
    }
  }

  Future<Cart> addToCart({
    required int userId,
    required Product product,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': product.id, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final cart = Cart.fromJson(data);
      _saveUserCart(userId, cart.products);
      return cart;
    }

    _addProductLocally(userId: userId, product: product, quantity: quantity);
    final fallbackCart = _buildSessionCart(userId);
    if (fallbackCart == null) {
      throw Exception('Failed to add product to cart');
    }
    return fallbackCart;
  }

  void _saveUserCart(int userId, List<CartProduct> products) {
    final byId = <int, CartProduct>{};
    for (final product in products) {
      byId[product.id] = product;
    }
    _sessionCartProductsByUser[userId] = byId;
  }

  void _addProductLocally({
    required int userId,
    required Product product,
    required int quantity,
  }) {
    final existingProducts = _sessionCartProductsByUser[userId] ?? {};
    final existing = existingProducts[product.id];
    final newQuantity = (existing?.quantity ?? 0) + quantity;
    final total = product.price * newQuantity;
    final discount = total * product.discountPercentage / 100;

    existingProducts[product.id] = CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: newQuantity,
      total: total,
      discountPercentage: product.discountPercentage,
      discountedTotal: total - discount,
      thumbnail: product.thumbnail,
    );

    _sessionCartProductsByUser[userId] = existingProducts;
  }

  Cart? _buildSessionCart(int userId) {
    final products = _sessionCartProductsByUser[userId]?.values.toList() ?? const <CartProduct>[];
    if (products.isEmpty) {
      return null;
    }

    final total = products.fold<double>(0, (sum, product) => sum + product.total);
    final discountedTotal = products.fold<double>(0, (sum, product) => sum + product.discountedTotal);

    return Cart(
      id: 0,
      products: products,
      total: total,
      discountedTotal: discountedTotal,
      userId: userId,
      totalProducts: products.length,
      totalQuantity: products.fold<int>(0, (sum, product) => sum + product.quantity),
    );
  }
}
