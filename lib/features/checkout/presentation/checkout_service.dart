import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../domain/payment_method_model.dart';
import '../../kasir/domain/order_item_model.dart';

class CheckoutService {
  static Future<List<PaymentMethod>> fetchPaymentMethods(String token) async {
    try {
      print('🔗 Calling API: ${ApiConfig.baseUrl}/payment-methods');
      print('🔑 Token: ${token.substring(0, 20)}...'); // Partial token untuk security
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payment-methods'),
        headers: ApiConfig.headers(token),
      ).timeout(const Duration(seconds: 10));

      print('📊 Response Status: ${response.statusCode}');
      print('📋 Response Body: ${response.body}');

      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        print('✅ Success: ${body['data'].length} payment methods found');
        return (body['data'] as List)
            .map((e) => PaymentMethod.fromJson(e))
            .toList();
      } else {
        print('❌ API Error: ${body['message']}');
        throw Exception('Gagal mengambil metode pembayaran: ${body['message']}');
      }
    } catch (e) {
      print('🚨 Exception: $e');
      rethrow;
    }
  }

  static Future<void> submitOrder({
    required String token,
    required String name,
    required int paymentMethodId,
    required List<OrderItem> cart,
    required int totalPrice,
    int? paymentAmount,
  }) async {
    final body = {
      'name': name,
      'payment_method_id': paymentMethodId,
      'total_price': totalPrice,
      'payment_amount': paymentAmount,
      'items': cart
          .map((e) => {
                'product_id': e.product.id,
                'quantity': e.quantity,
                'unit_price': e.product.price,
              })
          .toList(),
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: {
        ...ApiConfig.headers(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Gagal mengirim pesanan');
    }
  }
}
  