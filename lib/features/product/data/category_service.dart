import 'dart:convert';
import 'dart:io'; // Import untuk SocketException
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../domain/category_model.dart';

class CategoryService {
  static Future<List<Category>> fetchCategories(String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/categories');
    
    try {
      final response = await http.get(
        url,
        headers: ApiConfig.headers(token),
      );

      // Perbaikan 1: Selalu cek status code sebelum memproses body
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        if (body['success'] == true && body['data'] is List) {
          return (body['data'] as List)
              .map((json) => Category.fromJson(json))
              .toList();
        } else {
          // Jika success == false atau format data salah
          throw Exception(body['message'] ?? 'Format data tidak valid');
        }
      } else {
        // Jika server error (misal: 404, 500)
        throw Exception('Gagal memuat kategori (Status: ${response.statusCode})');
      }
    } on SocketException {
      // Perbaikan 2: Tangani error koneksi internet
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } catch (e) {
      // Tangani semua error lainnya
      rethrow;
    }
  }
}
