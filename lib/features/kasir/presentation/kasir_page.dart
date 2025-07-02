import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../product/presentation/product_controller.dart';
import '../../product/domain/product_model.dart';
import '../domain/order_item_model.dart';
import '../../kasir/presentation/kasir_controller.dart';
import '../../checkout/presentation/checkout_page.dart';
import '../../product/presentation/category_controller.dart';
import '../../product/presentation/product_page.dart';

// Provider untuk memfilter produk berdasarkan kategori yang dipilih (re-use logic from product page)
final kasirFilteredProductsProvider = Provider<List<Product>>((ref) {
  final selectedCategoryId = ref.watch(selectedCategoryProvider);
  final productsAsyncValue = ref.watch(productControllerProvider);

  return productsAsyncValue.when(
    data: (products) {
      if (selectedCategoryId == null) {
        return products;
      }
      return products.where((p) => p.categoryId == selectedCategoryId).toList();
    },
    loading: () => [],
    error: (e, st) => [],
  );
});

class KasirPage extends ConsumerWidget {
  const KasirPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productControllerProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Kasir'),
        elevation: 1,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Widget untuk filter kategori
          const CategoryFilterChips(),
          // Daftar produk dalam bentuk Grid
          Expanded(
            child: productsState.when(
              data: (list) {
                final filteredList = ref.watch(kasirFilteredProductsProvider);
                if (list.isEmpty) {
                  return const Center(child: Text('Tidak ada produk tersedia.'));
                }
                if (filteredList.isEmpty) {
                  return const Center(child: Text('Tidak ada produk dalam kategori ini.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    return KasirProductGridItem(product: filteredList[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isNotEmpty ? const CartSummaryBar() : null,
    );
  }
}

// Widget untuk setiap item produk dalam Grid di halaman Kasir
class KasirProductGridItem extends ConsumerWidget {
  final Product product;
  const KasirProductGridItem({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartItem = cart.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => OrderItem(product: product, quantity: 0),
    );
    final remainingStock = product.stock - cartItem.quantity;
    final bool isOutOfStock = remainingStock <= 0;

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
                'Stok: $remainingStock',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
          // Tombol tambah/kurang
          Positioned(
            bottom: 8,
            right: 8,
            child: cartItem.quantity == 0
                ? ElevatedButton(
                    onPressed: isOutOfStock ? null : () => cartNotifier.addToCart(product),
                    child: const Text('Tambah'),
                  )
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 20,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          icon: const Icon(Icons.remove),
                          onPressed: () => cartNotifier.decreaseQuantity(product),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            '${cartItem.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          iconSize: 20,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          icon: const Icon(Icons.add),
                          onPressed: isOutOfStock ? null : () => cartNotifier.addToCart(product),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk bar ringkasan keranjang di bagian bawah
class CartSummaryBar extends ConsumerWidget {
  const CartSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.watch(cartProvider.notifier);
    final totalItems = cartNotifier.totalItems;
    final totalPrice = cartNotifier.totalPrice;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$totalItems Item di Keranjang', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(totalPrice),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutPage()),
              );
            },
            child: const Row(
              children: [
                Text('Lanjut'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
