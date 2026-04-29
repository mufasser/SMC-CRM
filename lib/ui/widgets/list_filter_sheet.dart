import 'package:flutter/material.dart';
import '../../core/models/listing_filters.dart';

Future<ListingFilters?> showListingFilterSheet(
  BuildContext context, {
  required ListingFilters initialFilters,
  required String title,
}) {
  return showModalBottomSheet<ListingFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ListingFilterSheet(
      initialFilters: initialFilters,
      title: title,
    ),
  );
}

class _ListingFilterSheet extends StatefulWidget {
  final ListingFilters initialFilters;
  final String title;

  const _ListingFilterSheet({
    required this.initialFilters,
    required this.title,
  });

  @override
  State<_ListingFilterSheet> createState() => _ListingFilterSheetState();
}

class _ListingFilterSheetState extends State<_ListingFilterSheet> {
  late final TextEditingController _mileageMinController;
  late final TextEditingController _mileageMaxController;
  late final TextEditingController _priceMinController;
  late final TextEditingController _priceMaxController;
  late DateTime? _dateFrom;
  late DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initialFilters.dateFrom;
    _dateTo = widget.initialFilters.dateTo;
    _mileageMinController = TextEditingController(
      text: widget.initialFilters.mileageMin?.toString() ?? '',
    );
    _mileageMaxController = TextEditingController(
      text: widget.initialFilters.mileageMax?.toString() ?? '',
    );
    _priceMinController = TextEditingController(
      text: widget.initialFilters.priceMin?.toString() ?? '',
    );
    _priceMaxController = TextEditingController(
      text: widget.initialFilters.priceMax?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _mileageMinController.dispose();
    _mileageMaxController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Date Range',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dateButton(
                      label: _dateFrom == null ? 'From date' : _formatDate(_dateFrom!),
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dateButton(
                      label: _dateTo == null ? 'To date' : _formatDate(_dateTo!),
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Mileage Range',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      controller: _mileageMinController,
                      label: 'Min mileage',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _numberField(
                      controller: _mileageMaxController,
                      label: 'Max mileage',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Price Range',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      controller: _priceMinController,
                      label: 'Min price',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _numberField(
                      controller: _priceMaxController,
                      label: 'Max price',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(ListingFilters.empty),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _apply,
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initialDate =
        isFrom ? (_dateFrom ?? _dateTo ?? now) : (_dateTo ?? _dateFrom ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isFrom) {
        _dateFrom = picked;
        if (_dateTo != null && _dateTo!.isBefore(picked)) {
          _dateTo = picked;
        }
      } else {
        _dateTo = picked;
        if (_dateFrom != null && _dateFrom!.isAfter(picked)) {
          _dateFrom = picked;
        }
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      ListingFilters(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        mileageMin: int.tryParse(_mileageMinController.text.trim()),
        mileageMax: int.tryParse(_mileageMaxController.text.trim()),
        priceMin: int.tryParse(_priceMinController.text.trim()),
        priceMax: int.tryParse(_priceMaxController.text.trim()),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }
}
