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
    final title = [
      make,
      model,
    ].whereType<String>().where((e) => e.isNotEmpty).join(' ');
    return title.isEmpty ? stockNumber : title;
  }

  String get displayRegistration {
    return (registrationNumber == null || registrationNumber!.trim().isEmpty)
        ? stockNumber
        : registrationNumber!;
  }

  String? get primaryImageUrl => images.isNotEmpty ? images.first : null;

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
      currencyCode: _stringValue(json['currencyCode'], fallback: '£'),
      customerName: _nullableString(json['customerName']),
      customerEmail: _nullableString(json['customerEmail']),
      customerPhone: _nullableString(json['customerPhone']),
      customerWhatsapp: _nullableString(json['customerWhatsapp']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      images: _extractImageUrls(imageList),
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

  String? get primaryImage => galleryImages.isNotEmpty ? galleryImages.first : null;

  List<String> get galleryImages {
    final ordered = <String>[];
    if (featuredImage != null && featuredImage!.trim().isNotEmpty) {
      ordered.add(featuredImage!.trim());
    }
    for (final image in images) {
      if (image.trim().isEmpty || ordered.contains(image)) {
        continue;
      }
      ordered.add(image);
    }
    return ordered;
  }

  factory StockDetailModel.fromJson(Map<String, dynamic> json) {
    final imageList = (json['images'] as List?) ?? const [];
    return StockDetailModel(
      id: _stringValue(json['id']),
      dealer: DealerInfo.fromJson(
        (json['dealer'] as Map<String, dynamic>?) ?? const {},
      ),
      lead: json['lead'] == null
          ? null
          : StockLeadInfo.fromJson(json['lead'] as Map<String, dynamic>),
      stock: StockInfo.fromJson(
        (json['stock'] as Map<String, dynamic>?) ?? const {},
      ),
      customer: StockCustomer.fromJson(
        (json['customer'] as Map<String, dynamic>?) ?? const {},
      ),
      vehicle: StockVehicle.fromJson(
        (json['vehicle'] as Map<String, dynamic>?) ?? const {},
      ),
      images: _extractImageUrls(imageList),
      featuredImage: _extractImageUrl(json['featuredImage']),
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
      currencyCode: _stringValue(json['currencyCode'], fallback: '£'),
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

class StockGalleryImage {
  final String id;
  final String fileName;
  final String originalFileName;
  final String url;
  final String mimeType;
  final int fileSize;
  final bool isPublic;
  final int sortOrder;
  final DateTime? createdAt;

  const StockGalleryImage({
    required this.id,
    required this.fileName,
    required this.originalFileName,
    required this.url,
    required this.mimeType,
    required this.fileSize,
    required this.isPublic,
    required this.sortOrder,
    this.createdAt,
  });

  factory StockGalleryImage.fromJson(Map<String, dynamic> json) {
    return StockGalleryImage(
      id: _stringValue(json['id']),
      fileName: _stringValue(json['fileName']),
      originalFileName: _stringValue(
        json['originalFileName'],
        fallback: _stringValue(json['fileName']),
      ),
      url: _stringValue(json['url']),
      mimeType: _stringValue(json['mimeType'], fallback: 'image/jpeg'),
      fileSize: _nullableInt(json['fileSize']) ?? 0,
      isPublic: json['isPublic'] == true,
      sortOrder: _nullableInt(json['sortOrder']) ?? 0,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

class StockGalleryData {
  final List<StockGalleryImage> images;
  final String? featuredImageId;
  final StockGalleryImage? featuredImage;

  const StockGalleryData({
    required this.images,
    this.featuredImageId,
    this.featuredImage,
  });

  factory StockGalleryData.fromJson(Map<String, dynamic> json) {
    final imageList = (json['images'] as List?) ?? const [];
    return StockGalleryData(
      images: imageList
          .whereType<Map<String, dynamic>>()
          .map(StockGalleryImage.fromJson)
          .toList(),
      featuredImageId: _nullableString(json['featuredImageId']),
      featuredImage: json['featuredImage'] is Map<String, dynamic>
          ? StockGalleryImage.fromJson(
              json['featuredImage'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class StockBroadcastData {
  final StockBroadcastVehicle stockVehicle;
  final List<StockBroadcaster> broadcasters;
  final List<StockBroadcastLog> logs;

  const StockBroadcastData({
    required this.stockVehicle,
    required this.broadcasters,
    required this.logs,
  });

  factory StockBroadcastData.fromJson(Map<String, dynamic> json) {
    final payload = (json['data'] as Map<String, dynamic>?) ?? const {};
    final broadcasters = (payload['broadcasters'] as List?) ?? const [];
    final logs = (payload['logs'] as List?) ?? const [];

    return StockBroadcastData(
      stockVehicle: StockBroadcastVehicle.fromJson(
        (payload['stockVehicle'] as Map<String, dynamic>?) ?? const {},
      ),
      broadcasters: broadcasters
          .whereType<Map<String, dynamic>>()
          .map(StockBroadcaster.fromJson)
          .toList(),
      logs: logs
          .whereType<Map<String, dynamic>>()
          .map(StockBroadcastLog.fromJson)
          .toList(),
    );
  }
}

class StockBroadcastVehicle {
  final String id;
  final String stockStatus;
  final double? askPrice;
  final String? make;
  final String? model;
  final String? registrationNumber;

  const StockBroadcastVehicle({
    required this.id,
    required this.stockStatus,
    this.askPrice,
    this.make,
    this.model,
    this.registrationNumber,
  });

  String get displayTitle {
    final parts = [make, model]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' ');
    return parts.isEmpty ? id : parts;
  }

  factory StockBroadcastVehicle.fromJson(Map<String, dynamic> json) {
    return StockBroadcastVehicle(
      id: _stringValue(json['id']),
      stockStatus: _stringValue(json['stockStatus'], fallback: 'IN_STOCK'),
      askPrice: _nullableDouble(json['askPrice']),
      make: _nullableString(json['make']),
      model: _nullableString(json['model']),
      registrationNumber: _nullableString(json['registrationNumber']),
    );
  }
}

class StockBroadcaster {
  final String key;
  final String displayName;
  final String shortName;
  final String? websiteUrl;
  final String logoText;
  final String healthStatus;
  final String effectiveConnectionMode;
  final bool isEnabledByDealer;
  final bool autoSyncEnabled;
  final StockBroadcasterSyncState? syncState;

  const StockBroadcaster({
    required this.key,
    required this.displayName,
    required this.shortName,
    required this.logoText,
    required this.healthStatus,
    required this.effectiveConnectionMode,
    required this.isEnabledByDealer,
    required this.autoSyncEnabled,
    this.websiteUrl,
    this.syncState,
  });

  bool get isReady =>
      isEnabledByDealer && healthStatus.toUpperCase() == 'READY';

  factory StockBroadcaster.fromJson(Map<String, dynamic> json) {
    return StockBroadcaster(
      key: _stringValue(json['key']),
      displayName: _stringValue(json['displayName']),
      shortName: _stringValue(
        json['shortName'],
        fallback: _stringValue(json['displayName']),
      ),
      websiteUrl: _nullableString(json['websiteUrl']),
      logoText: _stringValue(json['logoText'], fallback: '--'),
      healthStatus: _stringValue(json['healthStatus'], fallback: 'UNKNOWN'),
      effectiveConnectionMode: _stringValue(
        json['effectiveConnectionMode'],
        fallback: 'UNKNOWN',
      ),
      isEnabledByDealer: json['isEnabledByDealer'] == true,
      autoSyncEnabled: json['autoSyncEnabled'] == true,
      syncState: json['syncState'] is Map<String, dynamic>
          ? StockBroadcasterSyncState.fromJson(
              json['syncState'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class StockBroadcasterSyncState {
  final String syncStatus;
  final bool isPublished;
  final String? externalListingId;
  final String? externalReference;
  final DateTime? publishedAt;
  final DateTime? lastSyncedAt;
  final DateTime? lastErrorAt;
  final String? lastErrorMessage;

  const StockBroadcasterSyncState({
    required this.syncStatus,
    required this.isPublished,
    this.externalListingId,
    this.externalReference,
    this.publishedAt,
    this.lastSyncedAt,
    this.lastErrorAt,
    this.lastErrorMessage,
  });

  factory StockBroadcasterSyncState.fromJson(Map<String, dynamic> json) {
    return StockBroadcasterSyncState(
      syncStatus: _stringValue(json['syncStatus'], fallback: 'UNKNOWN'),
      isPublished: json['isPublished'] == true,
      externalListingId: _nullableString(json['externalListingId']),
      externalReference: _nullableString(json['externalReference']),
      publishedAt: _parseDate(json['publishedAt']),
      lastSyncedAt: _parseDate(json['lastSyncedAt']),
      lastErrorAt: _parseDate(json['lastErrorAt']),
      lastErrorMessage: _nullableString(json['lastErrorMessage']),
    );
  }
}

class StockBroadcastLog {
  final String id;
  final String providerKey;
  final String? requestUrl;
  final String requestMethod;
  final int? responseStatus;
  final String? responseBody;
  final DateTime? createdAt;

  const StockBroadcastLog({
    required this.id,
    required this.providerKey,
    required this.requestMethod,
    this.requestUrl,
    this.responseStatus,
    this.responseBody,
    this.createdAt,
  });

  factory StockBroadcastLog.fromJson(Map<String, dynamic> json) {
    return StockBroadcastLog(
      id: _stringValue(json['id']),
      providerKey: _stringValue(json['providerKey']),
      requestUrl: _nullableString(json['requestUrl']),
      requestMethod: _stringValue(json['requestMethod'], fallback: 'POST'),
      responseStatus: _nullableInt(json['responseStatus']),
      responseBody: _nullableString(json['responseBody']),
      createdAt: _parseDate(json['createdAt']),
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

List<String> _extractImageUrls(List items) {
  return items
      .map(_extractImageUrl)
      .whereType<String>()
      .toList();
}

String? _extractImageUrl(dynamic value) {
  final dynamic candidate = value is Map<String, dynamic> ? value['url'] : value;
  final text = _nullableString(candidate);
  if (text == null) {
    return null;
  }
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    return null;
  }
  return text;
}
