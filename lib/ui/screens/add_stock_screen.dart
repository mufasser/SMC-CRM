import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/stock_model.dart';
import '../../data/services/crm_service.dart';
import '../../data/services/image_service.dart';
import '../widgets/uk_reg_plate.dart';

class AddStockScreen extends StatefulWidget {
  final StockModel? initialStock;

  const AddStockScreen({super.key, this.initialStock});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final CRMService _crmService = CRMService();
  final ImageService _imageService = ImageService();

  final List<XFile> _selectedImages = [];

  late final TextEditingController _regController;
  late final TextEditingController _mileageController;
  late final TextEditingController _makeController;
  late final TextEditingController _modelController;
  late final TextEditingController _variantController;
  late final TextEditingController _yearController;
  late final TextEditingController _colorController;
  late final TextEditingController _fuelController;
  late final TextEditingController _transmissionController;
  late final TextEditingController _priceController;

  bool _isFetching = false;
  bool _isSubmitting = false;
  bool _isPublic = true;

  bool get _isEditMode => widget.initialStock != null;

  @override
  void initState() {
    super.initState();
    final stock = widget.initialStock;
    _regController = TextEditingController(text: stock?.registrationNumber ?? '');
    _mileageController = TextEditingController(
      text: stock?.mileage?.toString() ?? '',
    );
    _makeController = TextEditingController(text: stock?.make ?? '');
    _modelController = TextEditingController(text: stock?.model ?? '');
    _variantController = TextEditingController(text: stock?.variant ?? '');
    _yearController = TextEditingController(
      text: stock?.registrationYear?.toString() ?? '',
    );
    _colorController = TextEditingController(text: stock?.colour ?? '');
    _fuelController = TextEditingController(text: stock?.fuelType ?? '');
    _transmissionController = TextEditingController(text: stock?.transmission ?? '');
    _priceController = TextEditingController(text: stock?.askPrice ?? '');
  }

  @override
  void dispose() {
    _regController.dispose();
    _mileageController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _fuelController.dispose();
    _transmissionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final img = await _imageService.takePhoto();
                if (img != null && mounted) {
                  setState(() => _selectedImages.add(img));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final imgs = await _imageService.pickGalleryImages();
                if (imgs.isNotEmpty && mounted) {
                  setState(() => _selectedImages.addAll(imgs));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchVehicleData() async {
    if (_regController.text.trim().isEmpty || _mileageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter registration and mileage first.')),
      );
      return;
    }

    setState(() => _isFetching = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }
    setState(() => _isFetching = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vehicle lookup API pending. I left the form ready for it.'),
      ),
    );
  }

  Future<void> _submitForm() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty && !_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one vehicle image.')),
      );
      return;
    }

    if (_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edit API not shared yet. Form is ready once endpoint is available.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      "stockStatus": "IN_STOCK",
      "isVisibleInApi": _isPublic,
      "registrationNumber": _regController.text.trim(),
      "make": _makeController.text.trim(),
      "model": _modelController.text.trim(),
      "variant": _variantController.text.trim().isEmpty
          ? null
          : _variantController.text.trim(),
      "registrationYear": int.tryParse(_yearController.text.trim()),
      "colour": _colorController.text.trim(),
      "fuelType": _fuelController.text.trim(),
      "transmission": _transmissionController.text.trim(),
      "mileage": int.tryParse(_mileageController.text.trim()),
      "askPrice": num.tryParse(_priceController.text.trim()),
      "currencyCode": "GBP",
    };

    final result = await _crmService.createStock(
      payload: payload,
      filePaths: _selectedImages.map((file) => file.path).toList(),
      isPublic: _isPublic,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock created successfully.')),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']?.toString() ?? 'Failed to create stock.'),
      ),
    );
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
      body: Form(
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
                        ? 'Update the fields below. Save is waiting for the edit endpoint.'
                        : 'Enter reg and mileage first, then you can fetch vehicle info later or fill the form manually now.',
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
                    subtitle: const Text('Matches your `isPublic` stock upload flag'),
                    onChanged: (value) => setState(() => _isPublic = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Gallery',
              subtitle: 'Upload multiple vehicle images',
              child: Column(
                children: [
                  SizedBox(
                    height: 108,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return GestureDetector(
                            onTap: _showImageSourceOptions,
                            child: Container(
                              width: 108,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: brandYellow.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: brandYellow.withValues(alpha: 0.45),
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: Colors.black),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add Images',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Stack(
                          children: [
                            Container(
                              width: 108,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                image: DecorationImage(
                                  image: FileImage(File(_selectedImages[index - 1].path)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 14,
                              top: 6,
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _selectedImages.removeAt(index - 1),
                                ),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black87,
                                  child: Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
                          controller: _transmissionController,
                          label: 'Transmission',
                          hint: 'Automatic',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildField(
                          controller: _priceController,
                          label: 'Ask Price',
                          hint: '9200',
                          isNumber: true,
                        ),
                      ),
                    ],
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
    TextCapitalization textCaps = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textCapitalization: textCaps,
      onChanged: (_) => setState(() {}),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (label == 'Variant' && text.isEmpty) {
          return null;
        }
        if (text.isEmpty) {
          return '$label is required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}
