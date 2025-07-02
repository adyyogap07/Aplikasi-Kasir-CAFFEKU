import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/order_item_model.dart';
import '../../product/domain/product_model.dart';

final cartProvider = StateNotifierProvider<CartController, List<OrderItem>>((ref) {
  return CartController();
});

class CartController extends StateNotifier<List<OrderItem>> {
  CartController() : super([]);

  void addToCart(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      state[index].quantity++;
      state = [...state];
    } else {
      state = [...state, OrderItem(product: product)];
    }
  }

  void decreaseQuantity(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      if (state[index].quantity > 1) {
        state[index].quantity--;
        state = [...state];
      } else {
        removeFromCart(product);
      }
    }
  }

  void removeFromCart(Product product) {
    state = state.where((item) => item.product.id != product.id).toList();
  }

  void clearCart() {
    state = [];
  }

  int get totalPrice => state.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);
}
