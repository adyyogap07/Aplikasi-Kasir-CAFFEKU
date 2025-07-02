import 'package:http/http.dart' as http;
import 'dart:convert';
import '../domain/sales_report_model.dart';
import '../../../config/api_config.dart';

class SalesReportService {
  static Future<SalesReport> fetchDailyReport(String token, {required String date}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/order.dailyReport?date=$date'),
      headers: ApiConfig.headers(token),
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return SalesReport.fromJson(body);
    } else {
      throw Exception(body['message'] ?? 'Gagal mengambil laporan harian');
    }
  }

  static Future<SalesReport> fetchMonthlyReport(String token, {required String month}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/order.monthlyReport?month=$month'),
      headers: ApiConfig.headers(token),
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return SalesReport.fromJson(body);
    } else {
      throw Exception(body['message'] ?? 'Gagal mengambil laporan bulanan');
    }
  }

  static Future<SalesReport> fetchYearlyReport(String token, {required String year}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/order.yearlyReport?year=$year'),
      headers: ApiConfig.headers(token),
    );
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return SalesReport.fromJson(body);
    } else {
      throw Exception(body['message'] ?? 'Gagal mengambil laporan tahunan');
    }
  }
} 