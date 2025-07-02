import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_service.dart';
import '../../auth/data/auth_service.dart';

final loginControllerProvider = StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
  return LoginController(ref);
});

class LoginController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  String? token;

  LoginController(this.ref) : super(const AsyncData(null));

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      token = await AuthService.login(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token!);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
