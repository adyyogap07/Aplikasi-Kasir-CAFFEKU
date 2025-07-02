import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../config/api_config.dart';
import '../../../providers/global_provider.dart';

// Model untuk data grafik
class SalesReportData {
  final String label;
  final double total;
  final DateTime date;
  SalesReportData(
      {required this.label, required this.total, required this.date});
}

// PERBAIKAN TOTAL: Provider ini sekarang mengambil semua order dan memprosesnya di aplikasi
final salesReportProvider =
    FutureProvider.family<List<SalesReportData>, String>((ref, period) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('Token tidak ditemukan');

  // Selalu gunakan endpoint /orders
  final url = Uri.parse('${ApiConfig.baseUrl}/orders');
  final response = await http.get(url, headers: ApiConfig.headers(token));

  if (response.statusCode == 200) {
    final dynamic body = json.decode(response.body);

    List<dynamic> orders;
    if (body is Map<String, dynamic> && body['data'] is List) {
      orders = body['data'];
    } else if (body is List) {
      orders = body;
    } else {
      throw Exception('Format respon tidak dikenal');
    }

    if (orders.isEmpty) {
      return [];
    }

    // --- LOGIKA PEMROSESAN DATA ---
    final Map<String, double> salesByPeriod = {};
    final Map<String, DateTime> dateByPeriod = {};

    for (var order in orders) {
      if (order is! Map<String, dynamic>) continue;

      try {
        final date = DateTime.parse(order['created_at']);
        final price = double.tryParse(order['total_price'].toString()) ?? 0.0;

        String key;
        switch (period) {
          case 'monthly':
            // Kunci berdasarkan Tahun-Bulan, misal: "2024-06"
            key = DateFormat('yyyy-MM').format(date);
            break;
          case 'yearly':
            // Kunci berdasarkan Tahun, misal: "2024"
            key = DateFormat('yyyy').format(date);
            break;
          default: // 'daily'
            // Kunci berdasarkan Tahun-Bulan-Hari, misal: "2024-06-25"
            key = DateFormat('yyyy-MM-dd').format(date);
            break;
        }

        salesByPeriod.update(key, (value) => value + price,
            ifAbsent: () => price);
        // Simpan tanggal pertama untuk setiap periode untuk sorting
        dateByPeriod.putIfAbsent(key, () => date);
      } catch (e) {
        // Abaikan data yang formatnya salah
        print('Gagal memproses order item: $e');
      }
    }

    // Ubah data yang sudah dikelompokkan menjadi List<SalesReportData>
    final reportList = salesByPeriod.entries.map((entry) {
      String label;
      final date = dateByPeriod[entry.key]!;
      switch (period) {
        case 'monthly':
          label = DateFormat('MMMM yyyy', 'id_ID').format(date);
          break;
        case 'yearly':
          label = DateFormat('yyyy').format(date);
          break;
        default:
          label = DateFormat('d/M/yy').format(date);
          break;
      }
      return SalesReportData(
        label: label,
        total: entry.value,
        date: date,
      );
    }).toList();

    // Urutkan berdasarkan tanggal
    reportList.sort((a, b) => a.date.compareTo(b.date));

    // Jika laporan harian, ambil 7 hari terakhir saja
    if (period == 'daily' && reportList.length > 7) {
      return reportList.sublist(reportList.length - 7);
    }

    return reportList;
  } else {
    throw Exception('Gagal memuat laporan (Status: ${response.statusCode})');
  }
});

// Provider ini tidak diubah, agar tetap kompatibel dengan HomePage
final dailySalesReportProvider =
    FutureProvider<List<SalesReportData>>((ref) async {
  // Langsung memanggil provider utama dengan parameter 'daily'
  return ref.watch(salesReportProvider('daily').future);
});
