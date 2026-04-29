import 'package:flutter/material.dart';
import '../../data/models/stock_model.dart';
import '../../data/services/crm_service.dart';
import '../widgets/uk_reg_plate.dart';

class AddStockScreen extends StatefulWidget {
  final String? stockId;
  final StockModel? initialStock;

  const AddStockScreen({super.key, this.stockId, this.initialStock});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final CRMService _crmService = CRMService();
  List<String> _prefillImageUrls = [];
  StockDetailModel? _editDetail;

  late final TextEditingController _stockNumberController;
  late final TextEditingController _referenceNumberController;
  late final TextEditingController _regController;
  late final TextEditingController _mileageController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _variantController;
  late final TextEditingController _yearController;
  late final TextEditingController _bodyTypeController;
  late final TextEditingController _doorsController;
  late final TextEditingController _previousOwnersController;
  late final TextEditingController _colorController;
  late final TextEditingController _fuelController;
  late final TextEditingController _transmissionController;
  late final TextEditingController _engineSizeController;
  late final TextEditingController _vinController;
  late final TextEditingController _conditionNotesController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  bool _isFetching = false;
  bool _isDetailLoading = false;
  bool _isSubmitting = false;
  bool _isPublic = true;

  bool get _isEditMode => widget.stockId != null || widget.initialStock != null;

  @override
  void initState() {
    super.initState();
    final stock = widget.initialStock;
    _stockNumberController = TextEditingController(text: stock?.stockNumber ?? '');
    _referenceNumberController = TextEditingController(
      text: stock?.referenceNumber ?? '',
    );
    _regController = TextEditingController(
      text: stock?.registrationNumber ?? '',
    );
    _mileageController = TextEditingController(
      text: stock?.mileage?.toString() ?? '',
    );
    _makeController = TextEditingController(text: stock?.make ?? '');
    _modelController = TextEditingController(text: stock?.model ?? '');
    _variantController = TextEditingController(text: stock?.variant ?? '');
    _yearController = TextEditingController(
      text: stock?.registrationYear?.toString() ?? '',
    );
    _bodyTypeController = TextEditingController(text: stock?.bodyType ?? '');
    _doorsController = TextEditingController(text: '');
    _previousOwnersController = TextEditingController(
      text: stock?.previousOwners?.toString() ?? '',
    );
    _colorController = TextEditingController(text: stock?.colour ?? '');
    _fuelController = TextEditingController(text: stock?.fuelType ?? '');
    _transmissionController = TextEditingController(
      text: stock?.transmission ?? '',
    );
    _engineSizeController = TextEditingController(text: '');
    _vinController = TextEditingController(text: '');
    _conditionNotesController = TextEditingController(
      text: stock?.conditionNotes ?? '',
    );
    _descriptionController = TextEditingController(text: stock?.description ?? '');
    _priceController = TextEditingController(text: stock?.askPrice ?? '');
    _isPublic = stock?.isVisibleInApi ?? true;

    if (widget.stockId != null) {
      _loadEditDetail();
    }
  }

  @override
  void dispose() {
    _stockNumberController.dispose();
    _referenceNumberController.dispose();
    _regController.dispose();
    _mileageController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _yearController.dispose();
    _bodyTypeController.dispose();
    _doorsController.dispose();
    _previousOwnersController.dispose();
    _colorController.dispose();
    _fuelController.dispose();
    _transmissionController.dispose();
    _engineSizeController.dispose();
    _vinController.dispose();
    _conditionNotesController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadEditDetail() async {
    if (widget.stockId == null) {
      return;
    }

    setState(() => _isDetailLoading = true);
    final detail = await _crmService.fetchStockDetail(widget.stockId!);

    if (!mounted) {
      return;
    }

    if (detail != null) {
      _editDetail = detail;
      _stockNumberController.text = detail.stock.stockNumber;
      _referenceNumberController.text =
          detail.vehicle.referenceNumber ?? _referenceNumberController.text;
      _regController.text =
          detail.vehicle.registrationNumber ?? _regController.text;
      _makeController.text = detail.vehicle.make ?? _makeController.text;
      _modelController.text = detail.vehicle.model ?? _modelController.text;
      _variantController.text = detail.vehicle.variant ?? _variantController.text;
      _yearController.text =
          detail.vehicle.registrationYear?.toString() ?? _yearController.text;
      _bodyTypeController.text =
          detail.vehicle.bodyType ?? _bodyTypeController.text;
      _doorsController.text =
          detail.vehicle.doors?.toString() ?? _doorsController.text;
      _previousOwnersController.text =
          detail.vehicle.previousOwners?.toString() ??
          _previousOwnersController.text;
      _colorController.text = detail.vehicle.colour ?? _colorController.text;
      _fuelController.text = detail.vehicle.fuelType ?? _fuelController.text;
      _engineSizeController.text =
          detail.vehicle.engineSize ?? _engineSizeController.text;
      _transmissionController.text =
          detail.vehicle.transmission ?? _transmissionController.text;
      _mileageController.text =
          detail.vehicle.mileage?.toString() ?? _mileageController.text;
      _vinController.text = detail.vehicle.vin ?? _vinController.text;
      _conditionNotesController.text =
          detail.vehicle.conditionNotes ?? _conditionNotesController.text;
      _descriptionController.text =
          detail.vehicle.description ?? _descriptionController.text;
      _priceController.text =
          detail.stock.askPrice?.toStringAsFixed(0) ?? _priceController.text;
      _isPublic = detail.stock.isVisibleInApi;
    }

    setState(() => _isDetailLoading = false);
  }

  Future<void> _fetchVehicleData() async {
    if (_regController.text.trim().isEmpty ||
        _mileageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter registration and mileage first.')),
      );
      return;
    }

    setState(() => _isFetching = true);

    final result = await _crmService.fetchStockPrefill(
      registrationNumber: _regController.text.trim().toUpperCase(),
      mileage: int.tryParse(_mileageController.text.trim()) ?? 0,
    );

    if (!mounted) {
      return;
    }

    final success = result['success'] == true;
    final data = result['data'] as Map<String, dynamic>?;
    final prefill = (data?['prefill'] as Map<String, dynamic>?) ?? const {};
    final media = (data?['media'] as Map<String, dynamic>?) ?? const {};
    final mediaImages = (media['images'] as List?) ?? const [];
    final heroImage = media['heroImageUrl']?.toString();

    if (!success || prefill.isEmpty) {
      setState(() => _isFetching = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to find vehicle')));
      return;
    }

    final prefillUrls = {
      if (heroImage != null && heroImage.isNotEmpty) heroImage,
      ...mediaImages
          .map((item) {
            if (item is Map<String, dynamic>) {
              return item['imageUrl']?.toString() ?? '';
            }
            return '';
          })
          .where((item) => item.isNotEmpty),
    }.toList();

    setState(() {
      _regController.text =
          prefill['registrationNumber']?.toString() ?? _regController.text;
      _mileageController.text =
          prefill['mileage']?.toString() ?? _mileageController.text;
      _makeController.text = prefill['make']?.toString() ?? '';
      _modelController.text = prefill['model']?.toString() ?? '';
      _variantController.text = prefill['variant']?.toString() ?? '';
      _yearController.text = prefill['registrationYear']?.toString() ?? '';
      _bodyTypeController.text = prefill['bodyType']?.toString() ?? '';
      _colorController.text = prefill['colour']?.toString() ?? '';
      _fuelController.text = prefill['fuelType']?.toString() ?? '';
      _transmissionController.text = prefill['transmission']?.toString() ?? '';
      _engineSizeController.text = prefill['engineSize']?.toString() ?? '';
      _prefillImageUrls = prefillUrls;
      _isFetching = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Vehicle details loaded',
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final payload = _buildPayload();
    final result = _isEditMode && widget.stockId != null
        ? await _crmService.updateStock(stockId: widget.stockId!, payload: payload)
        : await _crmService.createStock(
            payload: payload,
            filePaths: const [],
            isPublic: _isPublic,
          );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Stock updated successfully.'
                : 'Stock created successfully. Use Manage Gallery from the stock list next.',
          ),
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Failed to create stock.',
        ),
      ),
    );
  }

  Map<String, dynamic> _buildPayload() {
    final detail = _editDetail;
    final stock = widget.initialStock;

    return <String, dynamic>{
      "stockStatus":
          detail?.stock.stockStatus ?? stock?.stockStatus ?? "IN_STOCK",
      "isVisibleInApi": _isPublic,
      "stockNumber": _stockNumberController.text.trim().isEmpty
          ? detail?.stock.stockNumber ?? stock?.stockNumber
          : _stockNumberController.text.trim(),
      "referenceNumber": _referenceNumberController.text.trim().isEmpty
          ? detail?.vehicle.referenceNumber ?? stock?.referenceNumber
          : _referenceNumberController.text.trim(),
      "registrationNumber": _regController.text.trim(),
      "make": _makeController.text.trim(),
      "model": _modelController.text.trim(),
      "variant": _variantController.text.trim().isEmpty
          ? detail?.vehicle.variant ?? stock?.variant
          : _variantController.text.trim(),
      "registrationYear": int.tryParse(_yearController.text.trim()),
      "bodyType": _bodyTypeController.text.trim().isEmpty
          ? detail?.vehicle.bodyType ?? stock?.bodyType
          : _bodyTypeController.text.trim(),
      "colour": _colorController.text.trim(),
      "doors": int.tryParse(_doorsController.text.trim()) ?? detail?.vehicle.doors,
      "previousOwners":
          int.tryParse(_previousOwnersController.text.trim()) ??
          detail?.vehicle.previousOwners ??
          stock?.previousOwners,
      "fuelType": _fuelController.text.trim(),
      "engineSize": _engineSizeController.text.trim().isEmpty
          ? detail?.vehicle.engineSize
          : _engineSizeController.text.trim(),
      "transmission": _transmissionController.text.trim(),
      "mileage": int.tryParse(_mileageController.text.trim()),
      "vin": _vinController.text.trim().isEmpty
          ? detail?.vehicle.vin
          : _vinController.text.trim(),
      "conditionNotes": _conditionNotesController.text.trim().isEmpty
          ? detail?.vehicle.conditionNotes ?? stock?.conditionNotes
          : _conditionNotesController.text.trim(),
      "description": _descriptionController.text.trim().isEmpty
          ? detail?.vehicle.description ?? stock?.description
          : _descriptionController.text.trim(),
      "askPrice":
          num.tryParse(_priceController.text.trim()) ?? detail?.stock.askPrice,
      "currencyCode":
          detail?.stock.currencyCode ?? stock?.currencyCode ?? "GBP",
      "customerName": detail?.customer.name ?? stock?.customerName,
      "customerEmail": detail?.customer.email ?? stock?.customerEmail,
      "customerPhone": detail?.customer.phone ?? stock?.customerPhone,
      "customerWhatsapp": detail?.customer.whatsapp ?? stock?.customerWhatsapp,
    };
  }

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFFACC14);
    const brandBlack = Color(0xFF000000);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Stock' : 'Create Stock',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitForm,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: brandBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _isDetailLoading
          ? const Center(child: CircularProgressIndicator(color: brandYellow))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Start',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditMode
                        ? 'Update the stock information below and save your changes.'
                        : 'Create the stock vehicle first. After that, use Manage Gallery from the stock list to upload and arrange photos.',
                    style: TextStyle(color: Colors.grey[700], height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildField(
                          controller: _regController,
                          label: 'Registration',
                          hint: 'NT06KVJ',
                          textCaps: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _buildField(
                          controller: _mileageController,
                          label: 'Mileage',
                          hint: '12222',
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 56,
                        width: 56,
                        child: ElevatedButton(
                          onPressed: _isFetching ? null : _fetchVehicleData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: brandYellow,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isFetching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.bolt),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      UkRegPlate(
                        reg: _regController.text.trim().isEmpty
                            ? 'REG'
                            : _regController.text.trim(),
                        fontSize: 16,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: brandYellow.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _mileageController.text.trim().isEmpty
                              ? 'Mileage pending'
                              : "${_mileageController.text.trim()} miles",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: brandBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isPublic,
                    activeThumbColor: brandYellow,
                    activeTrackColor: brandYellow.withValues(alpha: 0.35),
                    title: const Text(
                      'Visible In API',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Controls whether this stock item is visible in the API',
                    ),
                    onChanged: (value) => setState(() => _isPublic = value),
                  ),
                ],
              ),
            ),
            if (_prefillImageUrls.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSection(
                title: 'Vehicle Preview',
                subtitle:
                    'Reference images returned by the vehicle prefill service',
                child: SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _prefillImageUrls.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return Container(
                        width: 108,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          image: DecorationImage(
                            image: NetworkImage(_prefillImageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildSection(
              title: 'Vehicle Details',
              subtitle: 'Required fields for stock creation',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _stockNumberController,
                                label: 'Stock Number',
                                hint: 'STK-NT06KVJ',
                                isRequired: false,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildField(
                                controller: _referenceNumberController,
                                label: 'Reference',
                                hint: 'REF-1001',
                                isRequired: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                        child: _buildField(
                          controller: _makeController,
                          label: 'Make',
                          hint: 'Volkswagen',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          controller: _modelController,
                          label: 'Model',
                          hint: 'Golf GTi Auto',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _variantController,
                          label: 'Variant',
                          hint: 'GTI',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          controller: _yearController,
                          label: 'Year',
                          hint: '2006',
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _bodyTypeController,
                          label: 'Body Type',
                          hint: '5 DOOR HATCHBACK',
                          isRequired: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          controller: _colorController,
                          label: 'Colour',
                          hint: 'GREY',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          controller: _fuelController,
                          label: 'Fuel Type',
                          hint: 'Petrol',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _doorsController,
                          label: 'Doors',
                          hint: '5',
                          isRequired: false,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          controller: _previousOwnersController,
                          label: 'Previous Owners',
                          hint: '2',
                          isRequired: false,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _transmissionController,
                          label: 'Transmission',
                          hint: 'Automatic',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          controller: _engineSizeController,
                          label: 'Engine Size',
                          hint: '1984',
                          isRequired: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _priceController,
                          label: 'Ask Price',
                          hint: '9200',
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          controller: _mileageController,
                          label: 'Mileage',
                          hint: '12222',
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _vinController,
                    label: 'VIN',
                    hint: 'WVWZZZ1KZ6W000001',
                    isRequired: false,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _conditionNotesController,
                    label: 'Condition Notes',
                    hint: 'Updated from mobile app',
                    isRequired: false,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Retail ready',
                    isRequired: false,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(_isEditMode ? 'Save Changes' : 'Create Stock'),
              ),
            ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], height: 1.3),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumber = false,
    bool isRequired = true,
    TextCapitalization textCaps = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textCapitalization: textCaps,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (!isRequired && text.isEmpty) {
          return null;
        }
        if (text.isEmpty) {
          return '$label is required';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
