import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/category_model.dart';
import '../data/category_service.dart';
import '../../../providers/global_provider.dart';

// PERBAIKAN 1: Provider disederhanakan.
// Kita tidak lagi me-watch token di sini.
final categoryControllerProvider = StateNotifierProvider<CategoryController, AsyncValue<List<Category>>>((ref) {
  // Controller akan otomatis memuat data saat pertama kali dipanggil.
  return CategoryController(ref)..fetchCategories();
});

class CategoryController extends StateNotifier<AsyncValue<List<Category>>> {
  // PERBAIKAN 2: Konstruktor disederhanakan, tidak lagi menerima token.
  CategoryController(this.ref) : super(const AsyncValue.loading());

  final Ref ref;
  // Variabel 'token' dihapus dari sini.

  Future<void> fetchCategories() async {
    // Pastikan state diatur ke loading setiap kali fetch dipanggil.
    state = const AsyncValue.loading();
    
    try {
      // PERBAIKAN 3: Token dibaca di dalam method, tepat saat dibutuhkan.
      final token = ref.read(authTokenProvider);

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login.');
      }
      
      final categories = await CategoryService.fetchCategories(token);
      
      // Cek apakah widget masih ada sebelum update state
      if (mounted) {
        state = AsyncValue.data(categories);
      }
    } catch (e, st) {
      // Cek apakah widget masih ada sebelum update state
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}
