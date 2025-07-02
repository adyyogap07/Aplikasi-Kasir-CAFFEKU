class PaymentMethod {
  final int id;
  final String name;
  final String? image;
  final int isCash;
  final String? imageUrl;
  final String? deletedAt;

  PaymentMethod({
    required this.id,
    required this.name,
    this.image,
    required this.isCash,
    this.imageUrl,
    this.deletedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      isCash: int.tryParse(json['is_cash'].toString()) ?? 0,
      imageUrl: json['image_url'],
      deletedAt: json['deleted_at'],
    );
  }
}