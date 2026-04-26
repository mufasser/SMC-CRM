import 'package:flutter/material.dart';
import '../../data/models/car_model.dart';
import '../../data/services/image_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImageService _imageService = ImageService();
  final List<XFile> _selectedImages = [];

  final TextEditingController _regController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isFetching = false;

  // --- IMAGE PICKER LOGIC ---
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
                if (img != null) setState(() => _selectedImages.add(img));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final imgs = await _imageService.pickGalleryImages();
                if (imgs.isNotEmpty)
                  setState(() => _selectedImages.addAll(imgs));
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- API FETCH SIMULATION ---
  Future<void> _fetchVehicleData() async {
    if (_regController.text.isEmpty) return;
    setState(() => _isFetching = true);
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Placeholder for your Valuation API
    setState(() {
      _makeController.text = "BMW"; // Data from API
      _modelController.text = "M4";
      _yearController.text = "2022";
      _colorController.text = "San Marino Blue";
      _isFetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "New Stock Entry",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _submitForm,
            icon: const Icon(Icons.check_circle, color: Colors.blue, size: 28),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 15),

            // 1. COMPACT TOP ROW
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Aligns button with fields
              children: [
                Expanded(
                  flex: 3,
                  child: _buildCompactField(
                    controller: _regController,
                    label: "Registration",
                    textCaps: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildCompactField(
                    controller: _mileageController,
                    label: "Mileage",
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48, // Matches height of compact fields
                  width: 48,
                  child: ElevatedButton(
                    onPressed: _isFetching ? null : _fetchVehicleData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                        : const Icon(Icons.bolt, color: Colors.amber, size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // 2. IMAGE SECTION
            _buildImageGallery(),

            const SizedBox(height: 20),

            // 3. VEHICLE DETAILS (Grid Layout)
            Row(
              children: [
                Expanded(
                  child: _buildCompactField(
                    controller: _makeController,
                    label: "Make",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCompactField(
                    controller: _modelController,
                    label: "Model",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildCompactField(
                    controller: _yearController,
                    label: "Year",
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCompactField(
                    controller: _colorController,
                    label: "Color",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildCompactField(
              controller: _priceController,
              label: "Asking Price (£)",
              isNumber: true,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildCompactField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
    TextCapitalization textCaps = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textCapitalization: textCaps,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ), // Reduced height
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade100),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gallery",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.add_a_photo,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                );
              }
              return Stack(
                children: [
                  Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImages[index - 1].path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedImages.removeAt(index - 1)),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
    }
  }
}
