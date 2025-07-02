class SimpleOrder {
  final int id;
  final String name;
  final int totalPrice;
  final DateTime createdAt;
  final PaymentMethod paymentMethod;
  final List<SimpleOrderProduct> orderProducts;

  SimpleOrder({
    required this.id,
    required this.name,
    required this.totalPrice,
    required this.createdAt,
    required this.paymentMethod,
    required this.orderProducts,
  });

  factory SimpleOrder.fromJson(Map<String, dynamic> json) {
    return SimpleOrder(
      id: json['id'],
      name: json['name'],
      totalPrice: json['total_price'],
      createdAt: DateTime.parse(json['created_at']),
      paymentMethod: PaymentMethod.fromJson(json['payment_method']),
      orderProducts: (json['order_products'] as List)
          .map((e) => SimpleOrderProduct.fromJson(e))
          .toList(),
    );
  }
}

class SimpleOrderProduct {
  final int productId;
  final String productName;
  final int quantity;
  final int unitPrice;

  SimpleOrderProduct({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  factory SimpleOrderProduct.fromJson(Map<String, dynamic> json) {
    return SimpleOrderProduct(
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'],
    );
  }
}

class PaymentMethod {
  final int id;
  final String name;
  final String imageUrl;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
    );
  }
} 