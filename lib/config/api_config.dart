class ApiConfig {
  static const baseUrl = 'https://mutiarasandi.my.id/api';

  static Map<String, String> headers(String? token) => {
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
