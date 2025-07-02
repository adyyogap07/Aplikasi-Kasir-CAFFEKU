import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:collection/collection.dart';

// --- IMPORT BARU ---
import '../../../config/api_config.dart'; // <-- Impor file config Anda

import '../../product/domain/product_model.dart';
import '../../product/data/product_service.dart';
import '../../../providers/global_provider.dart';

//== Provider (Tidak ada perubahan) ==
final productControllerProvider = StateNotifierProvider<ProductController, AsyncValue<List<Product>>>((ref) {
  return ProductController(ref)..fetchProducts();
});

final groupedProductsProvider = Provider<Map<String, List<Product>>>((ref) {
  // ... (Logika provider ini sudah benar, tidak perlu diubah)
  return ref.watch(productControllerProvider).when(
    data: (products) {
      products.sort((a, b) => a.name.compareTo(b.name));
      final grouped = groupBy(products, (Product p) => p.categoryName);
      final sortedGrouped = Map.fromEntries(
        grouped.entries.toList()
          ..sort((e1, e2) => e1.key.compareTo(e2.key)),
      );
      return sortedGrouped;
    },
    loading: () => {},
    error: (e, st) => {},
  );
});

final sortedProductsByCategoryProvider = Provider<Map<String, List<Product>>>((ref) {
  // ... (Logika provider ini sudah benar, tidak perlu diubah)
  final selectedCategoryId = ref.watch(selectedCategoryProvider);
  return ref.watch(productControllerProvider).when(
    data: (products) {
      List<Product> filteredProducts = products;
      if (selectedCategoryId != null) {
        filteredProducts = products.where((product) => product.categoryId == selectedCategoryId).toList();
      }
      filteredProducts.sort((a, b) => a.name.compareTo(b.name));
      final grouped = groupBy(filteredProducts, (Product p) => p.categoryName);
      final sortedGrouped = Map.fromEntries(
        grouped.entries.toList()
          ..sort((e1, e2) => e1.key.compareTo(e2.key)),
      );
      return sortedGrouped;
    },
    loading: () => {},
    error: (e, st) => {},
  );
});

final selectedCategoryProvider = StateProvider<int?>((ref) => null);


//== Controller (Perubahan di sini) ==
class ProductController extends StateNotifier<AsyncValue<List<Product>>> {
  ProductController(this.ref) : super(const AsyncValue.loading());
  final Ref ref;

  Future<void> createProduct(Map<String, dynamic> data, {File? image}) async {
    final token = ref.read(authTokenProvider);
    if (token == null) throw Exception('Token tidak ditemukan.');
    
    final url = Uri.parse('${ApiConfig.baseUrl}/products');

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(ApiConfig.headers(token));

      data.forEach((key, value) {
        if (value is bool) {
          request.fields[key] = value ? '1' : '0';
        } else {
          request.fields[key] = value.toString();
        }
      });

      if (image != null) {
        // PENYESUAIAN: Kunci dikembalikan menjadi 'image'
        request.files.add(await http.MultipartFile.fromPath(
          'image', // <-- Kunci disesuaikan agar sama dengan backend
          image.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchProducts();
      } else {
        if (response.body.isNotEmpty) {
           final errorData = json.decode(response.body);
           final errorMessage = errorData['message'] ?? 'Gagal membuat produk.';
           throw Exception(errorMessage);
        } else {
           throw Exception('Gagal membuat produk (Status: ${response.statusCode})');
        }
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(int productId, Map<String, dynamic> data, {File? image}) async {
    final token = ref.read(authTokenProvider);
    if (token == null) throw Exception('Token tidak ditemukan.');
    
    final url = Uri.parse('${ApiConfig.baseUrl}/products/$productId');

    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(ApiConfig.headers(token));
      request.fields['_method'] = 'PUT';

      data.forEach((key, value) {
        if (value is bool) {
          request.fields[key] = value ? '1' : '0';
        } else {
          request.fields[key] = value.toString();
        }
      });

      if (image != null) {
        // PENYESUAIAN: Kunci dikembalikan menjadi 'image'
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchProducts();
      } else {
         if (response.body.isNotEmpty) {
           final errorData = json.decode(response.body);
           final errorMessage = errorData['message'] ?? 'Gagal memperbarui produk.';
           throw Exception(errorMessage);
        } else {
           throw Exception('Gagal memperbarui produk (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchProducts() async {
    final token = ref.read(authTokenProvider);
    if (token == null) {
      state = AsyncValue.error('Token tidak ditemukan.', StackTrace.current);
      return;
    }
    try {
      final products = await ProductService.fetchProducts(token);
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProduct(int productId) async {
    final token = ref.read(authTokenProvider);
    if (token == null) {
      throw Exception('Token tidak ditemukan.');
    }
    
    final currentState = state;
    state = state.whenData((products) => products.where((p) => p.id != productId).toList());

    try {
      await ProductService.deleteProduct(token, productId);
    } catch (e) {
      state = currentState;
      rethrow;
    }
  }
}
