import '../../../config/api_config.dart'; // Pastikan path ini benar

class Product {
  final int id;
  final String name;
  final int price;
  final int stock;
  final int categoryId;
  final String categoryName;
  final String? imageUrl; // Ini akan menyimpan URL lengkap dari server

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
  });

  // Getter ini sekarang akan bekerja dengan benar karena 'imageUrl' akan selalu berisi URL lengkap
  String? get fullImageUrl {
    // Jika imageUrl dari server tidak ada (null) atau kosong, kembalikan null
    if (imageUrl == null || imageUrl!.isEmpty) {
      return null;
    }
    
    // Logika ini tetap dipertahankan sebagai fallback jika suatu saat API mengirim path relatif
    if (imageUrl!.startsWith('http')) {
      return imageUrl;
    }

    final baseUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    return '$baseUrl$imageUrl';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'] ?? 0,
      stock: json['stock'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      // Catatan: 'categoryName' mungkin tidak berfungsi jika API tidak menyertakan objek 'category'
      categoryName: json['category']?['name'] ?? 'Tanpa Kategori',
      
      // --- PERBAIKAN UTAMA DI SINI ---
      // Langsung gunakan field 'image_url' yang berisi URL lengkap dari server.
      imageUrl: json['image_url'], 
    );
  }
}
