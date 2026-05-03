import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  static const int _targetQuality = 82;
  static const int _minWidth = 1920;
  static const int _minHeight = 1920;

  Future<List<XFile>> pickGalleryImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isEmpty) {
        return [];
      }
      return _optimizeImages(images);
    } catch (e) {
      debugPrint("Error picking images: $e");
      return [];
    }
  }

  Future<XFile?> takePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (image == null) {
        return null;
      }

      final optimized = await _optimizeImage(image);
      return optimized ?? image;
    } catch (e) {
      debugPrint("Error taking photo: $e");
      return null;
    }
  }

  Future<List<XFile>> _optimizeImages(List<XFile> images) async {
    final optimized = <XFile>[];

    for (final image in images) {
      final converted = await _optimizeImage(image);
      optimized.add(converted ?? image);
    }

    return optimized;
  }

  Future<XFile?> _optimizeImage(XFile image) async {
    try {
      final sourcePath = image.path;
      if (sourcePath.trim().isEmpty) {
        return null;
      }

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      final bytes = await sourceFile.length();
      final sanitizedName = _sanitizeBaseName(image.name);
      final targetPath =
          '${Directory.systemTemp.path}/'
          '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.webp';

      final convertedFile = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        format: CompressFormat.webp,
        quality: _targetQuality,
        minWidth: _minWidth,
        minHeight: _minHeight,
        keepExif: true,
      );

      if (convertedFile == null) {
        return null;
      }

      final converted = File(convertedFile.path);
      if (!await converted.exists()) {
        return null;
      }

      final convertedBytes = await converted.length();
      if (convertedBytes <= 0) {
        return null;
      }

      debugPrint(
        'Optimized image ${image.name}: '
        '${_formatKb(bytes)}KB -> ${_formatKb(convertedBytes)}KB',
      );

      return XFile(converted.path, mimeType: 'image/webp');
    } catch (e) {
      debugPrint('Image optimization failed for ${image.name}: $e');
      return null;
    }
  }

  String _sanitizeBaseName(String value) {
    final dotIndex = value.lastIndexOf('.');
    final base = dotIndex > 0 ? value.substring(0, dotIndex) : value;
    final cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return cleaned.isEmpty ? 'vehicle_image' : cleaned;
  }

  String _formatKb(int bytes) {
    return (bytes / 1024).toStringAsFixed(1);
  }
}
