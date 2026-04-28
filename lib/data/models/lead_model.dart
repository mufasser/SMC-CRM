class LeadModel {
  final String id;
  final String sourceType;
  final String sourceName;
  final String pipelineStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? enquiryTime;
  final String? preferredContactMethod;
  final String? bestTimeToContact;
  final String? extraNote;
  final bool isOfferRequested;
  final bool isPublishedToInventory;
  final VehicleDetails vehicle;
  final CustomerDetails customer;
  final String? valuationAmount;
  final String? valuationCurrency;

  LeadModel({
    required this.id,
    required this.sourceType,
    required this.sourceName,
    required this.pipelineStatus,
    required this.createdAt,
    required this.vehicle,
    required this.customer,
    this.updatedAt,
    this.enquiryTime,
    this.preferredContactMethod,
    this.bestTimeToContact,
    this.extraNote,
    this.isOfferRequested = false,
    this.isPublishedToInventory = false,
    this.valuationAmount,
    this.valuationCurrency,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    final valuations = (json['valuations'] as List?) ?? const [];
    final firstValuation = valuations.isNotEmpty
        ? valuations.first as Map<String, dynamic>
        : null;

    return LeadModel(
      id: _stringValue(json['id']),
      sourceType: _stringValue(json['sourceType'], fallback: 'API'),
      sourceName: _stringValue(json['sourceName']),
      pipelineStatus: _stringValue(json['pipelineStatus'], fallback: 'NEW_LEAD'),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      enquiryTime: _parseDate(json['enquiryTime']),
      preferredContactMethod: _nullableString(json['preferredContactMethod']),
      bestTimeToContact: _nullableString(json['bestTimeToContact']),
      extraNote: _nullableString(json['extraNote']),
      isOfferRequested: json['isOfferRequested'] == true,
      isPublishedToInventory: json['isPublishedToInventory'] == true,
      vehicle: VehicleDetails.fromJson(
        (json['vehicleDetails'] as Map<String, dynamic>?) ?? const {},
      ),
      customer: CustomerDetails.fromJson(
        (json['customerDetails'] as Map<String, dynamic>?) ?? const {},
      ),
      valuationAmount: firstValuation == null
          ? null
          : _nullableString(firstValuation['amount']),
      valuationCurrency: firstValuation == null
          ? null
          : _nullableString(firstValuation['currency']),
    );
  }
}

class VehicleDetails {
  final String make;
  final String model;
  final String? variant;
  final String registrationNumber;
  final int? registrationYear;
  final int mileage;
  final String? imageUrl;
  final String? bodyType;
  final String? colour;
  final String? fuelType;
  final String? transmission;
  final int? previousOwners;
  final String? engineCapacity;
  final String? vehicleClass;

  VehicleDetails({
    required this.make,
    required this.model,
    required this.registrationNumber,
    required this.mileage,
    this.variant,
    this.registrationYear,
    this.imageUrl,
    this.bodyType,
    this.colour,
    this.fuelType,
    this.transmission,
    this.previousOwners,
    this.engineCapacity,
    this.vehicleClass,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    final customFields = json['customFieldsJson'] as Map<String, dynamic>?;

    return VehicleDetails(
      make: _stringValue(json['make']),
      model: _stringValue(json['model']),
      variant: _nullableString(json['variant']),
      registrationNumber: _stringValue(json['registrationNumber']),
      registrationYear: _nullableInt(json['registrationYear']),
      mileage: _nullableInt(json['mileage']) ?? 0,
      imageUrl: _nullableString(customFields?['vehicleImage']),
      bodyType: _nullableString(json['bodyType']),
      colour: _nullableString(json['colour']),
      fuelType: _nullableString(json['fuelType']),
      transmission: _nullableString(json['transmission']),
      previousOwners: _nullableInt(json['previousOwners']),
      engineCapacity: _nullableString(customFields?['engineCapacity']),
      vehicleClass: _nullableString(customFields?['vehicleClass']),
    );
  }
}

class CustomerDetails {
  final String fullName;
  final String phoneNumber;
  final String? whatsappNumber;
  final String? email;
  final String? postcode;

  CustomerDetails({
    required this.fullName,
    required this.phoneNumber,
    this.whatsappNumber,
    this.email,
    this.postcode,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      fullName: _stringValue(json['fullName'], fallback: 'Unknown Customer'),
      phoneNumber: _stringValue(json['phoneNumber']),
      whatsappNumber: _nullableString(json['whatsappNumber']),
      email: _nullableString(json['email']),
      postcode: _nullableString(json['postcode']),
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

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
