import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_service.dart';
import '../domain/payment_method_model.dart';
import '../../../providers/global_provider.dart';

final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) async {
  final token = ref.watch(authTokenProvider);
  return await PaymentService.fetchPaymentMethods(token!);
});
