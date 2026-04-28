import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Pick multiple images from the phone gallery
  Future<List<XFile>> pickGalleryImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      return images;
    } catch (e) {
      debugPrint("Error picking images: $e");
      return [];
    }
  }

  // Take a fresh photo with the camera
  Future<XFile?> takePhoto() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Balanced for API upload
      );
    } catch (e) {
      debugPrint("Error taking photo: $e");
      return null;
    }
  }
}
