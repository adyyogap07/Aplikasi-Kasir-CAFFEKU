import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/sales_order_simple_model.dart';
import '../data/sales_order_service.dart';
import '../../../providers/global_provider.dart';

final salesOrderProvider = FutureProvider<List<SimpleOrder>>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) throw Exception('Token tidak ditemukan. Silakan login ulang.');
  return await SalesOrderService.fetchOrders(token);
}); 