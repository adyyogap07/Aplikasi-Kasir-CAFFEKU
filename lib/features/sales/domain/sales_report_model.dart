import 'package:kasirrrrr/features/product/domain/product_model.dart';

class SalesReport {
  final bool success;
  final String message;
  final Map<String, dynamic> period;
  final SalesSummary summary;
  final List<SalesOrder> orders;

  SalesReport({
    required this.success,
    required this.message,
    required this.period,
    required this.summary,
    required this.orders,
  });

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      success: json['success'],
      message: json['message'],
      period: json['period'],
      summary: SalesSummary.fromJson(json['summary']),
      orders: (json['orders'] as List)
          .map((e) => SalesOrder.fromJson(e))
          .toList(),
    );
  }
}

class SalesSummary {
  final int totalOrders;
  final int totalSales;
  final List<SalesProductSummary> products;

  SalesSummary({
    required this.totalOrders,
    required this.totalSales,
    required this.products,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    return SalesSummary(
      totalOrders: json['total_orders'],
      totalSales: json['total_sales'],
      products: (json['products'] as List)
          .map((e) => SalesProductSummary.fromJson(e))
          .toList(),
    );
  }
}

class SalesProductSummary {
  final int productId;
  final String productName;
  final int totalQuantity;
  final int totalSales;

  SalesProductSummary({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalSales,
  });

  factory SalesProductSummary.fromJson(Map<String, dynamic> json) {
    return SalesProductSummary(
      productId: json['product_id'],
      productName: json['product_name'],
      totalQuantity: json['total_quantity'],
      totalSales: json['total_sales'],
    );
  }
}

class SalesOrder {
  final int id;
  final String name;
  final String? email;
  final String gender;
  final String? phone;
  final String? birthday;
  final int totalPrice;
  final String? note;
  final int paymentMethodId;
  final int? paidAmount;
  final int? changeAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderProduct> orderProducts;
  final PaymentMethod paymentMethod;

  SalesOrder({
    required this.id,
    required this.name,
    this.email,
    required this.gender,
    this.phone,
    this.birthday,
    required this.totalPrice,
    this.note,
    required this.paymentMethodId,
    this.paidAmount,
    this.changeAmount,
    required this.createdAt,
    required this.updatedAt,
    required this.orderProducts,
    required this.paymentMethod,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      gender: json['gender'],
      phone: json['phone'],
      birthday: json['birthday'],
      totalPrice: json['total_price'],
      note: json['note'],
      paymentMethodId: json['payment_method_id'],
      paidAmount: json['paid_amount'],
      changeAmount: json['change_amount'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      orderProducts: (json['order_products'] as List)
          .map((e) => OrderProduct.fromJson(e))
          .toList(),
      paymentMethod: PaymentMethod.fromJson(json['payment_method']),
    );
  }
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