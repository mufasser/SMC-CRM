class StockExpenseModel {
  final String id;
  final String title;
  final String? category;
  final String? vendorName;
  final String? notes;
  final double amount;
  final String currencyCode;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StockExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.currencyCode,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.vendorName,
    this.notes,
  });

  factory StockExpenseModel.fromJson(Map<String, dynamic> json) {
    return StockExpenseModel(
      id: _stringValue(json['id']),
      title: _stringValue(json['title'], fallback: 'Expense'),
      category: _nullableString(json['category']),
      vendorName: _nullableString(json['vendorName']),
      notes: _nullableString(json['notes']),
      amount: _nullableDouble(json['amount']) ?? 0,
      currencyCode: _stringValue(json['currencyCode'], fallback: 'GBP'),
      expenseDate: _parseDate(json['expenseDate']) ?? DateTime.now(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

class StockExpenseSummary {
  final double totalExpenseAmount;
  final int expenseCount;
  final String currencyCode;

  const StockExpenseSummary({
    required this.totalExpenseAmount,
    required this.expenseCount,
    required this.currencyCode,
  });

  factory StockExpenseSummary.fromJson(Map<String, dynamic> json) {
    return StockExpenseSummary(
      totalExpenseAmount: _nullableDouble(json['totalExpenseAmount']) ?? 0,
      expenseCount: _nullableInt(json['expenseCount']) ?? 0,
      currencyCode: _stringValue(json['currencyCode'], fallback: 'GBP'),
    );
  }
}

class StockExpenseListData {
  final List<StockExpenseModel> expenses;
  final StockExpenseSummary summary;

  const StockExpenseListData({
    required this.expenses,
    required this.summary,
  });

  factory StockExpenseListData.fromJson(Map<String, dynamic> json) {
    final rawExpenses = (json['expenses'] as List?) ?? const [];
    return StockExpenseListData(
      expenses: rawExpenses
          .whereType<Map<String, dynamic>>()
          .map(StockExpenseModel.fromJson)
          .toList(),
      summary: StockExpenseSummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? const {},
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

double? _nullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}
