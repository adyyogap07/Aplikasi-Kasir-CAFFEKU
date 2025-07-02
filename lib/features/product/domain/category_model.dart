class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final int isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // PERBAIKAN: Membuat factory lebih aman terhadap data null dari server
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: int.tryParse(json['id'].toString()) ?? 0,
      
      // Memberikan nilai default '' (string kosong) jika 'name' null
      name: json['name'] ?? 'Tanpa Nama', 
      
      // Memberikan nilai default '' (string kosong) jika 'slug' null
      slug: json['slug'] ?? '',

      description: json['description'],
      
      isActive: int.tryParse(json['is_active'].toString()) ?? 0,
      
      // Memberikan nilai default string kosong jika tanggal null
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',

      deletedAt: json['deleted_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }
}
