import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/stock_model.dart';
import '../../data/services/crm_service.dart';
import '../../data/services/image_service.dart';
import '../widgets/uk_reg_plate.dart';

class StockGalleryScreen extends StatefulWidget {
  final String stockId;
  final String title;
  final String registration;

  const StockGalleryScreen({
    super.key,
    required this.stockId,
    required this.title,
    required this.registration,
  });

  @override
  State<StockGalleryScreen> createState() => _StockGalleryScreenState();
}

class _StockGalleryScreenState extends State<StockGalleryScreen> {
  final CRMService _crmService = CRMService();
  final ImageService _imageService = ImageService();

  List<StockGalleryImage> _images = [];
  String? _featuredImageId;
  String? _draggingImageId;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isSavingOrder = false;
  bool _hasPendingOrder = false;
  bool _isPublic = true;
  bool _didChangeGallery = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final gallery = await _crmService.fetchStockGallery(widget.stockId);

    if (!mounted) {
      return;
    }

    if (gallery == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load gallery right now.';
      });
      return;
    }

    final images = _normalizeGalleryImages(gallery);
    final featuredImageId = gallery.featuredImageId ?? gallery.featuredImage?.id;

    setState(() {
      _images = images;
      _featuredImageId = featuredImageId;
      _isLoading = false;
      _hasPendingOrder = false;
    });
  }

  List<StockGalleryImage> _normalizeGalleryImages(StockGalleryData gallery) {
    final uniqueImages = <String, StockGalleryImage>{};

    for (final image in gallery.images) {
      final normalizedUrl = image.url.trim();
      if (normalizedUrl.isEmpty) {
        continue;
      }
      uniqueImages[image.id] = StockGalleryImage(
        id: image.id,
        fileName: image.fileName,
        originalFileName: image.originalFileName,
        url: normalizedUrl,
        mimeType: image.mimeType,
        fileSize: image.fileSize,
        isPublic: image.isPublic,
        sortOrder: image.sortOrder,
        createdAt: image.createdAt,
      );
    }

    final featuredImage = gallery.featuredImage;
    if (featuredImage != null && featuredImage.url.trim().isNotEmpty) {
      uniqueImages[featuredImage.id] = StockGalleryImage(
        id: featuredImage.id,
        fileName: featuredImage.fileName,
        originalFileName: featuredImage.originalFileName,
        url: featuredImage.url.trim(),
        mimeType: featuredImage.mimeType,
        fileSize: featuredImage.fileSize,
        isPublic: featuredImage.isPublic,
        sortOrder: featuredImage.sortOrder,
        createdAt: featuredImage.createdAt,
      );
    }

    final images = uniqueImages.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return images;
  }

  Future<void> _showUploadOptions() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Add Gallery Images',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload one image or a full set for this vehicle gallery.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              _UploadOptionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Take Photo',
                subtitle: 'Capture a fresh vehicle shot now',
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              const SizedBox(height: 12),
              _UploadOptionTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                subtitle: 'Select one or more saved photos',
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) {
      return;
    }

    if (source == 'camera') {
      final image = await _imageService.takePhoto();
      if (image != null) {
        await _uploadImages([image]);
      }
      return;
    }

    final images = await _imageService.pickGalleryImages();
    if (images.isNotEmpty) {
      await _uploadImages(images);
    }
  }

  Future<void> _uploadImages(List<XFile> files) async {
    if (files.isEmpty) {
      return;
    }

    setState(() => _isUploading = true);

    final result = await _crmService.uploadStockImages(
      stockId: widget.stockId,
      filePaths: files.map((file) => file.path).toList(),
      isPublic: _isPublic,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isUploading = false);

    if (result['success'] == true) {
      _didChangeGallery = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Gallery updated successfully.',
          ),
        ),
      );
      await _loadGallery();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Failed to upload images.',
        ),
      ),
    );
  }

  Future<void> _setFeatured(String imageId) async {
    final result = await _crmService.updateStockGallery(
      stockId: widget.stockId,
      featuredImageId: imageId,
      orderedImageIds: _images.map((image) => image.id).toList(),
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      _didChangeGallery = true;
      await _loadGallery();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Featured image updated.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Unable to update featured image.',
        ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    if (_images.isEmpty || !_hasPendingOrder) {
      return;
    }

    setState(() => _isSavingOrder = true);

    final result = await _crmService.updateStockGallery(
      stockId: widget.stockId,
      featuredImageId: _featuredImageId,
      orderedImageIds: _images.map((image) => image.id).toList(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSavingOrder = false);

    if (result['success'] == true) {
      _didChangeGallery = true;
      await _loadGallery();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery order saved.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Unable to save gallery order.',
        ),
      ),
    );
  }

  Future<void> _deleteImage(StockGalleryImage image) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Remove this image from the stock gallery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    final result = await _crmService.deleteStockImage(
      stockId: widget.stockId,
      imageId: image.id,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      _didChangeGallery = true;
      final nextFeaturedImageId = result['featuredImageId']?.toString();
      setState(() {
        _images.removeWhere((item) => item.id == image.id);
        _featuredImageId = nextFeaturedImageId;
        _hasPendingOrder = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Image deleted successfully.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Unable to delete image.',
        ),
      ),
    );
  }

  void _moveDraggedImage(String targetImageId) {
    final draggingImageId = _draggingImageId;
    if (draggingImageId == null || draggingImageId == targetImageId) {
      return;
    }

    final oldIndex = _images.indexWhere((image) => image.id == draggingImageId);
    final newIndex = _images.indexWhere((image) => image.id == targetImageId);

    if (oldIndex == -1 || newIndex == -1) {
      return;
    }

    setState(() {
      final movedItem = _images.removeAt(oldIndex);
      _images.insert(newIndex, movedItem);
      _draggingImageId = null;
      _hasPendingOrder = true;
    });
  }

  void _openLargePreview(StockGalleryImage image) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: InteractiveViewer(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Image.network(
                    image.url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 52,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFFACC14);
    const brandBlack = Color(0xFF000000);

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, _didChangeGallery);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F5EF),
        appBar: AppBar(
          backgroundColor: brandYellow,
          foregroundColor: brandBlack,
          elevation: 0,
          title: const Text(
            'Manage Gallery',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: _hasPendingOrder && !_isSavingOrder ? _saveOrder : null,
              child: _isSavingOrder
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save Order',
                      style: TextStyle(
                        color: _hasPendingOrder ? brandBlack : Colors.black45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: brandYellow))
            : _errorMessage != null
            ? _buildErrorState()
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: [
                          _buildUsageCard(),
                          const SizedBox(height: 14),
                          _buildToolbar(),
                          const SizedBox(height: 18),
                          _buildSectionHeader(),
                        ],
                      ),
                    ),
                  ),
                  if (_images.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      sliver: SliverToBoxAdapter(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.9,
                              ),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            final image = _images[index];
                            final isFeatured = image.id == _featuredImageId;
                            return _buildGridItem(
                              image: image,
                              index: index,
                              isFeatured: isFeatured,
                              isDragging: image.id == _draggingImageId,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _showUploadOptions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlack,
                      foregroundColor: brandYellow,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: brandYellow,
                            ),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(_isUploading ? 'Uploading...' : 'Add Images'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _hasPendingOrder && !_isSavingOrder ? _saveOrder : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandBlack,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.swap_vert),
                    label: const Text('Save Order'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              UkRegPlate(reg: widget.registration, fontSize: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_images.length} images',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_hasPendingOrder)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC14).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Unsaved Order',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap image to open large. Tap star to make featured. Long press and drag to reorder.',
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New uploads are public',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use the star to set featured. Use delete to remove images.',
                  style: TextStyle(color: Colors.grey[600], height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: _isPublic,
            activeThumbColor: const Color(0xFFFACC14),
            activeTrackColor: const Color(0xFFFACC14).withValues(alpha: 0.35),
            onChanged: (value) => setState(() => _isPublic = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gallery Grid',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Featured image gets a yellow border. Others stay light grey.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required StockGalleryImage image,
    required int index,
    required bool isFeatured,
    required bool isDragging,
  }) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != image.id,
      onAcceptWithDetails: (details) => _moveDraggedImage(image.id),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final borderColor = isFeatured
            ? const Color(0xFFFACC14)
            : Colors.grey.shade300;

        return LongPressDraggable<String>(
          data: image.id,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragStarted: () => setState(() => _draggingImageId = image.id),
          onDragEnd: (_) => setState(() => _draggingImageId = null),
          onDraggableCanceled: (velocity, offset) =>
              setState(() => _draggingImageId = null),
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.92,
              child: Container(
                width: 160,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFACC14), width: 2),
                  image: DecorationImage(
                    image: NetworkImage(image.url),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.22,
            child: _GalleryThumb(
              image: image,
              index: index,
              borderColor: borderColor,
              isFeatured: isFeatured,
              onStarTap: isFeatured ? null : () => _setFeatured(image.id),
              onDeleteTap: () => _deleteImage(image),
              onTap: () => _openLargePreview(image),
            ),
          ),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: isHovering ? 0.97 : 1,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isDragging ? 0.65 : 1,
              child: _GalleryThumb(
                image: image,
                index: index,
                borderColor: isHovering
                    ? const Color(0xFFFACC14)
                    : borderColor,
                isFeatured: isFeatured,
                onStarTap: isFeatured ? null : () => _setFeatured(image.id),
                onDeleteTap: () => _deleteImage(image),
                onTap: () => _openLargePreview(image),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC14).withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 42,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No gallery images yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload the first set of images, then pick a featured photo and drag the rest into your preferred order.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _showUploadOptions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: const Color(0xFFFACC14),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Upload First Images'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      children: [
        const Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ElevatedButton(
            onPressed: _loadGallery,
            child: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  final StockGalleryImage image;
  final int index;
  final Color borderColor;
  final bool isFeatured;
  final VoidCallback? onStarTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onTap;

  const _GalleryThumb({
    required this.image,
    required this.index,
    required this.borderColor,
    required this.isFeatured,
    required this.onStarTap,
    required this.onDeleteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: isFeatured ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Image.network(
                    image.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.02),
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withValues(alpha: 0.95),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionCircle(
                      icon: isFeatured ? Icons.star : Icons.star_border,
                      iconColor: const Color(0xFFFACC14),
                      onTap: onStarTap,
                    ),
                    const SizedBox(width: 8),
                    _ActionCircle(
                      icon: Icons.delete_outline,
                      iconColor: Colors.redAccent,
                      onTap: onDeleteTap,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_full, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Open',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _ActionCircle({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: iconColor, size: 18),
        ),
      ),
    );
  }
}

class _UploadOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _UploadOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7F2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC14).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.black),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
