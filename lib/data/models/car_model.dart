enum CarStatus { lead, offerAccepted, negotiation, inStock, sold }

class CarImage {
  final String id;
  final String url;
  final bool isCover;
  final String? label;

  CarImage({
    required this.id,
    required this.url,
    this.isCover = false,
    this.label,
  });

  factory CarImage.fromJson(Map<String, dynamic> json) {
    return CarImage(
      id: json['id']?.toString() ?? '',
      url: json['url'] ?? '',
      isCover: json['is_cover'] ?? false,
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'url': url, 'is_cover': isCover, 'label': label};
  }
}

class CarModel {
  final String id;
  final String make;
  final String model;
  final String year;
  final String reg;
  final String color;
  final int mileage;
  final double price;
  final String? imageUrl; // Kept as primary thumbnail fallback
  final CarStatus status;
  final String? customerName;
  final String? phoneNumber;
  final List<CarImage> images;

  CarModel({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.reg,
    required this.color,
    required this.mileage,
    required this.price,
    this.imageUrl,
    required this.status,
    this.customerName,
    this.phoneNumber,
    this.images = const [],
  });

  // Smart Getter: Always returns a usable image URL for the list view
  String get displayImageUrl {
    if (images.isNotEmpty) {
      final cover = images.firstWhere(
        (img) => img.isCover,
        orElse: () => images.first,
      );
      return cover.url;
    }
    return imageUrl ?? "https://via.placeholder.com/400x300?text=No+Image";
  }

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id']?.toString() ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      year: json['year']?.toString() ?? '',
      reg: json['registration_number'] ?? '',
      mileage: json['mileage'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
      status: _parseStatus(json['status']),
      customerName: json['customer_name'],
      phoneNumber: json['phone_number'],
      // Fixed: Safe list parsing even if 'images' is null in JSON
      images: json['images'] != null
          ? (json['images'] as List).map((i) => CarImage.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'registration_number': reg,
      'color': color,
      'mileage': mileage,
      'price': price,
      'image_url': imageUrl,
      'status': status.name,
      'customer_name': customerName,
      'phone_number': phoneNumber,
      'images': images.map((i) => i.toJson()).toList(),
    };
  }

  static CarStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'lead':
        return CarStatus.lead;
      case 'offer_accepted':
        return CarStatus.offerAccepted;
      case 'negotiation':
        return CarStatus.negotiation;
      case 'instock':
      case 'in_stock':
        return CarStatus.inStock;
      case 'sold':
        return CarStatus.sold;
      default:
        return CarStatus.inStock;
    }
  }
}
