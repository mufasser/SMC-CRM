class ListingFilters {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? mileageMin;
  final int? mileageMax;
  final int? priceMin;
  final int? priceMax;

  const ListingFilters({
    this.dateFrom,
    this.dateTo,
    this.mileageMin,
    this.mileageMax,
    this.priceMin,
    this.priceMax,
  });

  bool get hasActiveFilters =>
      dateFrom != null ||
      dateTo != null ||
      mileageMin != null ||
      mileageMax != null ||
      priceMin != null ||
      priceMax != null;

  int get activeFilterCount {
    var count = 0;
    if (dateFrom != null || dateTo != null) {
      count++;
    }
    if (mileageMin != null || mileageMax != null) {
      count++;
    }
    if (priceMin != null || priceMax != null) {
      count++;
    }
    return count;
  }

  ListingFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    int? mileageMin,
    int? mileageMax,
    int? priceMin,
    int? priceMax,
    bool clearDateRange = false,
    bool clearMileage = false,
    bool clearPrice = false,
  }) {
    return ListingFilters(
      dateFrom: clearDateRange ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateRange ? null : (dateTo ?? this.dateTo),
      mileageMin: clearMileage ? null : (mileageMin ?? this.mileageMin),
      mileageMax: clearMileage ? null : (mileageMax ?? this.mileageMax),
      priceMin: clearPrice ? null : (priceMin ?? this.priceMin),
      priceMax: clearPrice ? null : (priceMax ?? this.priceMax),
    );
  }

  static const empty = ListingFilters();
}
