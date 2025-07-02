import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/global_provider.dart';
import '../data/sales_service.dart';
import '../domain/sales_order_model.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final salesProvider = FutureProvider<List<SalesOrder>>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) {
    throw Exception('Token tidak ditemukan. Silakan login.');
  }

  final selectedDate = ref.watch(selectedDateProvider);
  final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
  
  return SalesService.fetchSales(token, date: dateString);
}); 