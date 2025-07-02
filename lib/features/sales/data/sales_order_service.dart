import 'package:http/http.dart' as http;
import 'dart:convert';
import '../domain/sales_order_simple_model.dart';
import '../../../config/api_config.dart';

class SalesOrderService {
  static Future<List<SimpleOrder>> fetchOrders(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: ApiConfig.headers(token),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (body as List)
          .map((e) => SimpleOrder.fromJson(e))
          .toList();
    } else {
      throw Exception('Gagal mengambil data penjualan');
    }
  }
} 