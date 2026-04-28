class StockModel {
  final String id;
  final String? leadId;
  final String sourceType;
  final String stockStatus;
  final bool isVisibleInApi;
  final String stockNumber;
  final String? referenceNumber;
  final String? registrationNumber;
  final String? make;
  final String? model;
  final String? variant;
  final int? registrationYear;
  final String? bodyType;
  final String? colour;
  final int? previousOwners;
  final String? fuelType;
  final String? transmission;
  final int? mileage;
  final String? conditionNotes;
  final String? description;
  final String? askPrice;
  final String currencyCode;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerWhatsapp;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> images;

  const StockModel({
    required this.id,
    required this.sourceType,
    required this.stockStatus,
    required this.isVisibleInApi,
    required this.stockNumber,
    required this.currencyCode,
    required this.createdAt,
    this.leadId,
    this.referenceNumber,
    this.registrationNumber,
    this.make,
    this.model,
    this.variant,
    this.registrationYear,
    this.bodyType,
    this.colour,
    this.previousOwners,
    this.fuelType,
    this.transmission,
    this.mileage,
    this.conditionNotes,
    this.description,
    this.askPrice,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.customerWhatsapp,
    this.updatedAt,
    this.images = const [],
  });

  String get displayTitle {
    final title = [make, model].whereType<String>().where((e) => e.isNotEmpty).join(' ');
    return title.isEmpty ? stockNumber : title;
  }

  String get displayRegistration {
    return (registrationNumber == null || registrationNumber!.trim().isEmpty)
        ? stockNumber
        : registrationNumber!;
  }

  factory StockModel.fromJson(Map<String, dynamic> json) {
    final imageList = (json['images'] as List?) ?? const [];
    return StockModel(
      id: _stringValue(json['id']),
      leadId: _nullableString(json['leadId']),
      sourceType: _stringValue(json['sourceType'], fallback: 'UNKNOWN'),
      stockStatus: _stringValue(json['stockStatus'], fallback: 'IN_STOCK'),
      isVisibleInApi: json['isVisibleInApi'] == true,
      stockNumber: _stringValue(json['stockNumber'], fallback: 'STK'),
      referenceNumber: _nullableString(json['referenceNumber']),
      registrationNumber: _nullableString(json['registrationNumber']),
      make: _nullableString(json['make']),
      model: _nullableString(json['model']),
      variant: _nullableString(json['variant']),
      registrationYear: _nullableInt(json['registrationYear']),
      bodyType: _nullableString(json['bodyType']),
      colour: _nullableString(json['colour']),
      previousOwners: _nullableInt(json['previousOwners']),
      fuelType: _nullableString(json['fuelType']),
      transmission: _nullableString(json['transmission']),
      mileage: _nullableInt(json['mileage']),
      conditionNotes: _nullableString(json['conditionNotes']),
      description: _nullableString(json['description']),
      askPrice: _nullableString(json['askPrice']),
      currencyCode: _stringValue(json['currencyCode'], fallback: 'GBP'),
      customerName: _nullableString(json['customerName']),
      customerEmail: _nullableString(json['customerEmail']),
      customerPhone: _nullableString(json['customerPhone']),
      customerWhatsapp: _nullableString(json['customerWhatsapp']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      images: imageList
          .map((item) {
            if (item is Map<String, dynamic>) {
              return _nullableString(item['url']) ?? '';
            }
            return _nullableString(item) ?? '';
          })
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }
}

class StockDetailModel {
  final String id;
  final DealerInfo dealer;
  final StockLeadInfo? lead;
  final StockInfo stock;
  final StockCustomer customer;
  final StockVehicle vehicle;
  final List<String> images;
  final String? featuredImage;
  final StockSummary summary;

  const StockDetailModel({
    required this.id,
    required this.dealer,
    required this.stock,
    required this.customer,
    required this.vehicle,
    required this.summary,
    this.lead,
    this.images = const [],
    this.featuredImage,
  });

  String get primaryImage =>
      featuredImage ??
      (images.isNotEmpty ? images.first : 'https://via.placeholder.com/600');

  factory StockDetailModel.fromJson(Map<String, dynamic> json) {
    final imageList = (json['images'] as List?) ?? const [];
    return StockDetailModel(
      id: _stringValue(json['id']),
      dealer: DealerInfo.fromJson((json['dealer'] as Map<String, dynamic>?) ?? const {}),
      lead: json['lead'] == null
          ? null
          : StockLeadInfo.fromJson(json['lead'] as Map<String, dynamic>),
      stock: StockInfo.fromJson((json['stock'] as Map<String, dynamic>?) ?? const {}),
      customer: StockCustomer.fromJson(
        (json['customer'] as Map<String, dynamic>?) ?? const {},
      ),
      vehicle: StockVehicle.fromJson(
        (json['vehicle'] as Map<String, dynamic>?) ?? const {},
      ),
      images: imageList
          .map((item) {
            if (item is Map<String, dynamic>) {
              return _nullableString(item['url']) ?? '';
            }
            return _nullableString(item) ?? '';
          })
          .where((item) => item.isNotEmpty)
          .toList(),
      featuredImage: _nullableString(json['featuredImage']),
      summary: StockSummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class DealerInfo {
  final String id;
  final String name;
  final String slug;

  const DealerInfo({required this.id, required this.name, required this.slug});

  factory DealerInfo.fromJson(Map<String, dynamic> json) {
    return DealerInfo(
      id: _stringValue(json['id']),
      name: _stringValue(json['name']),
      slug: _stringValue(json['slug']),
    );
  }
}

class StockLeadInfo {
  final String id;
  final String pipelineStatus;

  const StockLeadInfo({required this.id, required this.pipelineStatus});

  factory StockLeadInfo.fromJson(Map<String, dynamic> json) {
    return StockLeadInfo(
      id: _stringValue(json['id']),
      pipelineStatus: _stringValue(json['pipelineStatus']),
    );
  }
}

class StockInfo {
  final String sourceType;
  final String stockStatus;
  final bool isVisibleInApi;
  final String stockNumber;
  final double? askPrice;
  final String currencyCode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StockInfo({
    required this.sourceType,
    required this.stockStatus,
    required this.isVisibleInApi,
    required this.stockNumber,
    required this.currencyCode,
    required this.createdAt,
    this.askPrice,
    this.updatedAt,
  });

  factory StockInfo.fromJson(Map<String, dynamic> json) {
    return StockInfo(
      sourceType: _stringValue(json['sourceType']),
      stockStatus: _stringValue(json['stockStatus']),
      isVisibleInApi: json['isVisibleInApi'] == true,
      stockNumber: _stringValue(json['stockNumber']),
      askPrice: _nullableDouble(json['askPrice']),
      currencyCode: _stringValue(json['currencyCode'], fallback: 'GBP'),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class StockCustomer {
  final String? name;
  final String? email;
  final String? phone;
  final String? whatsapp;

  const StockCustomer({this.name, this.email, this.phone, this.whatsapp});

  factory StockCustomer.fromJson(Map<String, dynamic> json) {
    return StockCustomer(
      name: _nullableString(json['name']),
      email: _nullableString(json['email']),
      phone: _nullableString(json['phone']),
      whatsapp: _nullableString(json['whatsapp']),
    );
  }
}

class StockVehicle {
  final String? referenceNumber;
  final String? registrationNumber;
  final String? make;
  final String? model;
  final String? variant;
  final int? registrationYear;
  final String? bodyType;
  final String? colour;
  final int? doors;
  final int? previousOwners;
  final String? fuelType;
  final String? engineSize;
  final String? transmission;
  final int? mileage;
  final String? vin;
  final String? conditionNotes;
  final String? description;

  const StockVehicle({
    this.referenceNumber,
    this.registrationNumber,
    this.make,
    this.model,
    this.variant,
    this.registrationYear,
    this.bodyType,
    this.colour,
    this.doors,
    this.previousOwners,
    this.fuelType,
    this.engineSize,
    this.transmission,
    this.mileage,
    this.vin,
    this.conditionNotes,
    this.description,
  });

  factory StockVehicle.fromJson(Map<String, dynamic> json) {
    return StockVehicle(
      referenceNumber: _nullableString(json['referenceNumber']),
      registrationNumber: _nullableString(json['registrationNumber']),
      make: _nullableString(json['make']),
      model: _nullableString(json['model']),
      variant: _nullableString(json['variant']),
      registrationYear: _nullableInt(json['registrationYear']),
      bodyType: _nullableString(json['bodyType']),
      colour: _nullableString(json['colour']),
      doors: _nullableInt(json['doors']),
      previousOwners: _nullableInt(json['previousOwners']),
      fuelType: _nullableString(json['fuelType']),
      engineSize: _nullableString(json['engineSize']),
      transmission: _nullableString(json['transmission']),
      mileage: _nullableInt(json['mileage']),
      vin: _nullableString(json['vin']),
      conditionNotes: _nullableString(json['conditionNotes']),
      description: _nullableString(json['description']),
    );
  }
}

class StockSummary {
  final int imageCount;
  final bool hasLinkedLead;
  final bool hasFeaturedImage;

  const StockSummary({
    required this.imageCount,
    required this.hasLinkedLead,
    required this.hasFeaturedImage,
  });

  factory StockSummary.fromJson(Map<String, dynamic> json) {
    return StockSummary(
      imageCount: _nullableInt(json['imageCount']) ?? 0,
      hasLinkedLead: json['hasLinkedLead'] == true,
      hasFeaturedImage: json['hasFeaturedImage'] == true,
    );
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
}

double? _nullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
