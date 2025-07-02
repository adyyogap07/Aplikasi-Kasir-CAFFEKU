import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../domain/product_model.dart';
import '../../../config/api_config.dart';
import 'package:mime/mime.dart';

class ProductService {
  static Future<List<Product>> fetchProducts(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products'),
      headers: ApiConfig.headers(token),
    );

    final body = jsonDecode(response.body);
    if (body['success']) {
      return (body['data'] as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } else {
      throw Exception(body['message']);
    }
  }

  static Future<void> createProduct(String token, Map<String, Object> data, {File? image}) async {
    if (image != null) {
      final bytes = await image.readAsBytes();
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      data['image'] = 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/products'),
      headers: {
        ...ApiConfig.headers(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      if (response.body.isNotEmpty) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal membuat produk');
      } else {
        throw Exception('Gagal membuat produk (response kosong)');
      }
    }
  }

  static Future<void> updateProduct(String token, int productId, Map<String, Object> data, {File? image}) async {
    if (image != null) {
      final bytes = await image.readAsBytes();
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
      data['image'] = 'data:$mimeType;base64,${base64Encode(bytes)}';
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/products/$productId'),
      headers: {
        ...ApiConfig.headers(token),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      if (response.body.isNotEmpty) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal memperbarui produk');
      } else {
        throw Exception('Gagal memperbarui produk (response kosong)');
      }
    }
  }

  static Future<void> deleteProduct(String token, int productId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/products/$productId'),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal menghapus produk');
    }
  }
}
