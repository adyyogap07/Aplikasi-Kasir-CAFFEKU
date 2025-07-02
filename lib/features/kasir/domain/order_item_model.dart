import '../../product/domain/product_model.dart';

class OrderItem {
  final Product product;
  int quantity;

  OrderItem({required this.product, this.quantity = 1});

  int get totalPrice => quantity * product.price;
}
