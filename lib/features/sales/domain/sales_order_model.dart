import 'package:kasirrrrr/features/product/domain/product_model.dart';

class SalesOrder {
  final int? id; // id lokal SQLite
  final String orderNumber;
  final double total;
  final String customer;
  final DateTime createdAt;
  final String status; // 'pending' atau 'sent'

  SalesOrder({
    this.id,
    required this.orderNumber,
    required this.total,
    required this.customer,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'orderNumber': orderNumber,
    'total': total,
    'customer': customer,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };

  factory SalesOrder.fromMap(Map<String, dynamic> map) => SalesOrder(
    id: map['id'],
    orderNumber: map['orderNumber'],
    total: map['total'],
    customer: map['customer'],
    createdAt: DateTime.parse(map['createdAt']),
    status: map['status'],
  );
}

class OrderProduct {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final int unitPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Product product;

  OrderProduct({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      product: Product.fromJson(json['product']),
    );
  }
}

class PaymentMethod {
  final int id;
  final String name;
  final String image;
  final int isCash;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String imageUrl;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.image,
    required this.isCash,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.imageUrl,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      isCash: json['is_cash'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      imageUrl: json['image_url'],
    );
  }
}

// Gunakan Product model yang sudah ada di project Anda untuk bagian product di OrderProduct