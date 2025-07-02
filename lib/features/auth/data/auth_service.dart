import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const baseUrl =
      'https://mutiarasandi.my.id/api'; // atau gunakan ngrok jika perlu

  static Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['success'] == true) {
      return body['data']['access_token'];
    } else {
      throw Exception(body['message'] ?? 'Login gagal');
    }
  }
}
