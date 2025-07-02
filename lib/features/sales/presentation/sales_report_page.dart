import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../config/api_config.dart';
import '../../../providers/global_provider.dart';

// Model yang lebih umum untuk data laporan
class SalesReportData {
  final String label; // Contoh: "24/06", "Juni", "2024"
  final double total;
  final DateTime date; // Digunakan untuk sorting

  SalesReportData({required this.label, required this.total, required this.date});
}

// PERBAIKAN: Menggunakan .family untuk menerima parameter
// Parameter 'period' bisa berupa 'daily', 'monthly', atau 'yearly'
final salesReportProvider = FutureProvider.family<List<SalesReportData>, String>((ref, period) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) {
    throw Exception('Token tidak ditemukan');
  }

  // Tentukan endpoint API berdasarkan periode yang diminta
  String endpoint;
  switch (period) {
    case 'monthly':
      endpoint = '${ApiConfig.baseUrl}/orders/report/monthly';
      break;
    case 'yearly':
      endpoint = '${ApiConfig.baseUrl}/orders/report/yearly';
      break;
    default: // 'daily'
      endpoint = '${ApiConfig.baseUrl}/orders/report/daily';
      break;
  }
  
  final url = Uri.parse(endpoint);
  final response = await http.get(url, headers: ApiConfig.headers(token));

  if (response.statusCode == 200) {
    final List<dynamic> reportData = json.decode(response.body)['data'];
    
    return reportData.map((item) {
      // Proses data berdasarkan periode
      DateTime date;
      String label;
      
      switch (period) {
        case 'monthly':
          date = DateTime.parse(item['month']);
          label = DateFormat('MMMM', 'id_ID').format(date);
          break;
        case 'yearly':
          date = DateTime(int.parse(item['year']));
          label = item['year'].toString();
          break;
        default: // 'daily'
          date = DateTime.parse(item['date']);
          label = DateFormat('d/M').format(date);
          break;
      }

      return SalesReportData(
        label: label,
        total: double.parse(item['total'].toString()),
        date: date
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // Urutkan berdasarkan tanggal

  } else {
    throw Exception('Gagal memuat laporan penjualan');
  }
});

// Provider untuk Home Page tetap menggunakan endpoint 'daily'
// Ini untuk kompatibilitas dengan grafik di HomePage
final dailySalesReportProvider = FutureProvider<List<SalesReportData>>((ref) async {
    return ref.watch(salesReportProvider('daily').future);
});
