import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../providers/global_provider.dart';
import '../domain/payment_method_model.dart';

class PaymentService {
  static const baseUrl = 'https://kasir.dewakoding.com/api';

  static Future<List<PaymentMethod>> fetchPaymentMethods(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payment-methods'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil metode pembayaran: ${response.statusCode}');
    }

    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return (body['data'] as List)
          .map((e) => PaymentMethod.fromJson(e))
          .toList();
    } else {
      throw Exception('Gagal mengambil metode pembayaran');
    }
  }
}
