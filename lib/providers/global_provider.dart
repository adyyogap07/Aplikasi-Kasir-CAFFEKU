import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/domain/user_model.dart';
import 'package:flutter/foundation.dart'; // Pastikan Anda punya model User yang sesuai

// Di file providers/global_provider.dart atau file provider Anda
final authTokenProvider = StateProvider<String?>((ref) => null);
