import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../domain/sales_order_model.dart';

class SalesService {
  static Future<List<SalesOrder>> fetchSales(String token, {String? date}) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/orders');
    if (date != null) {
      uri = uri.replace(queryParameters: {'date': date});
    }

    final response = await http.get(
      uri,
      headers: ApiConfig.headers(token),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success']) {
      return (body['data'] as List)
          .map((json) => SalesOrder.fromJson(json))
          .toList();
    } else {
      throw Exception(body['message'] ?? 'Gagal mengambil data penjualan');
    }
  }
} 