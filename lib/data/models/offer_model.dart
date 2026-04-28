import 'lead_model.dart';

class OfferModel {
  final String id;
  final String leadId;
  final String amount;
  final String currency;
  final String? message;
  final DateTime? expiresAt;
  final String status;
  final DateTime? sentAt;
  final DateTime? viewedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final int followUpAttemptCount;
  final DateTime? nextFollowUpAt;
  final DateTime? lastFollowUpAt;
  final DateTime? followUpCompletedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final LeadModel lead;

  OfferModel({
    required this.id,
    required this.leadId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.lead,
    this.message,
    this.expiresAt,
    this.sentAt,
    this.viewedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.followUpAttemptCount = 0,
    this.nextFollowUpAt,
    this.lastFollowUpAt,
    this.followUpCompletedAt,
    this.updatedAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: _stringValue(json['id']),
      leadId: _stringValue(json['leadId']),
      amount: _stringValue(json['amount'], fallback: '0'),
      currency: _stringValue(json['currency'], fallback: 'GBP'),
      message: _nullableString(json['message']),
      expiresAt: _parseDate(json['expiresAt']),
      status: _stringValue(json['status'], fallback: 'PENDING'),
      sentAt: _parseDate(json['sentAt']),
      viewedAt: _parseDate(json['viewedAt']),
      acceptedAt: _parseDate(json['acceptedAt']),
      rejectedAt: _parseDate(json['rejectedAt']),
      followUpAttemptCount: _nullableInt(json['followUpAttemptCount']) ?? 0,
      nextFollowUpAt: _parseDate(json['nextFollowUpAt']),
      lastFollowUpAt: _parseDate(json['lastFollowUpAt']),
      followUpCompletedAt: _parseDate(json['followUpCompletedAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      lead: LeadModel.fromJson(
        (json['lead'] as Map<String, dynamic>?) ?? const {},
      ),
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
