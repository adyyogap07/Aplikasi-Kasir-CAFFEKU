import '../../product/domain/product_model.dart';

class OrderItem {
  final Product product;
  int quantity;

  OrderItem({required this.product, this.quantity = 1});

  int get totalPrice => quantity * product.price;

  OrderItem copyWith({Product? product, int? quantity}) {
    return OrderItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
