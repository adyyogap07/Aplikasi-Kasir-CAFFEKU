import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/product_model.dart';
import '../presentation/category_controller.dart';
import '../presentation/product_controller.dart';
import 'product_form_page.dart';

// Provider untuk memfilter produk berdasarkan kategori yang dipilih
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final selectedCategoryId = ref.watch(selectedCategoryProvider);
  final productsAsyncValue = ref.watch(productControllerProvider);

  return productsAsyncValue.when(
    data: (products) {
      if (selectedCategoryId == null) {
        // Jika tidak ada kategori yang dipilih (Tampilkan Semua), kembalikan semua produk
        return products;
      }
      // Filter produk berdasarkan categoryId
      return products.where((p) => p.categoryId == selectedCategoryId).toList();
    },
    // Kembalikan list kosong saat loading atau error
    loading: () => [],
    error: (e, st) => [],
  );
});

class ProductPage extends ConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productControllerProvider);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tambahkan judul custom
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: const Text(
                'Data Produk',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Widget untuk filter kategori
            const CategoryFilterChips(),
            // Daftar produk dalam bentuk Grid
            Expanded(
              child: productsState.when(
                data: (list) {
                  // Menggunakan provider baru untuk mendapatkan produk yang sudah difilter
                  final filteredList = ref.watch(filteredProductsProvider);

                  if (list.isEmpty) {
                    return const Center(child: Text('Belum ada produk. Ketuk + untuk menambah.'));
                  }
                  if (filteredList.isEmpty) {
                    return const Center(child: Text('Tidak ada produk dalam kategori ini.'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 produk per baris
                      childAspectRatio: 0.8, // Rasio untuk membuat kartu sedikit lebih tinggi
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return ProductGridItem(product: filteredList[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget untuk menampilkan chip kategori secara horizontal
class CategoryFilterChips extends ConsumerWidget {
  const CategoryFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoryControllerProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final selectedCategoryNotifier = ref.read(selectedCategoryProvider.notifier);

    return categoriesState.when(
      data: (categories) => Container(
        height: 60,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // Chip untuk "Semua Kategori"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: const Text('Semua'),
                selected: selectedCategoryId == null,
                onSelected: (selected) {
                  if (selected) selectedCategoryNotifier.state = null;
                },
              ),
            ),
            // Chip untuk setiap kategori
            ...categories.map((category) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: selectedCategoryId == category.id,
                    onSelected: (selected) {
                      if (selected) selectedCategoryNotifier.state = category.id;
                    },
                  ),
                )),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 60),
      error: (e, st) => Container(
        height: 60,
        alignment: Alignment.center,
        color: Colors.red.shade50,
        child: Text('Gagal memuat kategori', style: TextStyle(color: Colors.red.shade700)),
      ),
    );
  }
}

// Widget untuk setiap item produk dalam Grid
class ProductGridItem extends ConsumerWidget {
  final Product product;

  const ProductGridItem({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar produk
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: product.fullImageUrl != null
                      ? Image.network(
                          product.fullImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                        )
                      : const Icon(Icons.inventory, color: Colors.grey, size: 40),
                ),
              ),
              // Detail Produk
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(product.price),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Indikator Stok
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Stok: ${product.stock}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
          // Menu Aksi (Edit/Hapus)
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
                  );
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Konfirmasi Hapus'),
                      content: Text('Anda yakin ingin menghapus produk "${product.name}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await ref.read(productControllerProvider.notifier).deleteProduct(product.id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${product.name}" berhasil dihapus.'), backgroundColor: Colors.green));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

