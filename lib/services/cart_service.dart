import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';
import '../models/product.dart';

class CartService {
  // Enhancement 3: Stores products added through the simulated /carts/add API
  // so the Cart screen only shows items added in this app session.
  static final Map<int, CartProduct> _cartProducts = {};

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

  // Enhancement 3: Uses only the selected user's app-session cart. DummyJSON's
  // /carts/add endpoint is simulated, so products added here are tracked
  // locally instead of showing the API's preloaded sample carts.
  Future<Cart?> getCartByUserId(int userId) async {
    if (_cartProducts.isEmpty) {
      return null;
    }

    final products = _cartProducts.values.toList();
    final total = products.fold<double>(
      0,
      (sum, product) => sum + product.total,
    );
    final discountedTotal = products.fold<double>(
      0,
      (sum, product) => sum + product.discountedTotal,
    );

    return Cart(
      id: 0,
      products: products,
      total: total,
      discountedTotal: discountedTotal,
      userId: userId,
      totalProducts: products.length,
      totalQuantity: products.fold<int>(
        0,
        (sum, product) => sum + product.quantity,
      ),
    );
  }

  // Enhancement 3: Cart API integration by user id from the documentation:
  // GET /carts/user/{userId}. This reads DummyJSON's seeded cart data for one
  // user, but CartScreen uses getCartByUserId so the UI only shows items added
  // in the app.
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

  // Enhancement 3: Calls POST /carts/add by passing values from the selected
  // Product into the cart payload.
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
      _addProductLocally(product: product, quantity: quantity);
      return (await getCartByUserId(userId))!;
    } else {
      throw Exception('Failed to add product to cart');
    }
  }

  void _addProductLocally({
    required Product product,
    required int quantity,
  }) {
    // Enhancement 3: Converts the selected Product values into CartProduct
    // values after the add-to-cart API call succeeds.
    final existing = _cartProducts[product.id];
    final newQuantity = (existing?.quantity ?? 0) + quantity;
    final total = product.price * newQuantity;
    final discount = total * product.discountPercentage / 100;

    _cartProducts[product.id] = CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: newQuantity,
      total: total,
      discountPercentage: product.discountPercentage,
      discountedTotal: total - discount,
      thumbnail: product.thumbnail,
    );
  }
}
