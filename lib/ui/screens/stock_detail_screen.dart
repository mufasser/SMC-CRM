import 'package:flutter/material.dart';
import '../../data/models/stock_model.dart';
import '../../data/services/crm_service.dart';
import 'add_stock_screen.dart';
import 'stock_gallery_screen.dart';
import '../widgets/uk_reg_plate.dart';

class StockDetailScreen extends StatefulWidget {
  final String stockId;
  final StockModel? initialStock;

  const StockDetailScreen({super.key, required this.stockId, this.initialStock});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final CRMService _crmService = CRMService();
  final PageController _galleryController = PageController();

  StockDetailModel? _detail;
  bool _isLoading = true;
  String? _errorMessage;
  int _activeImageIndex = 0;
  String? _localStatusOverride;

  String get _currentStatus => _localStatusOverride ?? _detail?.stock.stockStatus ?? 'IN_STOCK';

  bool get _canEdit => _currentStatus.toUpperCase() != 'SOLD';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final detail = await _crmService.fetchStockDetail(widget.stockId);

    if (!mounted) {
      return;
    }

    setState(() {
      _detail = detail;
      _isLoading = false;
      _activeImageIndex = 0;
      if (detail == null) {
        _errorMessage = 'Unable to load stock details right now.';
      }
    });
  }

  List<String> get _galleryImages {
    final images = _detail?.images ?? const <String>[];
    if (_detail?.featuredImage != null && _detail!.featuredImage!.isNotEmpty) {
      return [_detail!.featuredImage!, ...images.where((e) => e != _detail!.featuredImage!)];
    }
    if (images.isNotEmpty) {
      return images;
    }
    return ['https://via.placeholder.com/900x600?text=No+Image'];
  }

  Future<void> _showChangeStatusSheet() async {
    final nextStatus = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
              'Change Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Endpoint not shared yet, so this updates the UI state for now.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Mark In Stock'),
              onTap: () => Navigator.pop(context, 'IN_STOCK'),
            ),
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: const Text('Mark Sold'),
              onTap: () => Navigator.pop(context, 'SOLD'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (nextStatus == null || !mounted) {
      return;
    }

    setState(() => _localStatusOverride = nextStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status changed to $nextStatus on this screen.')),
    );
  }

  void _handleBroadcast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Broadcast action is ready in UI. Share the endpoint and I will wire it.'),
      ),
    );
  }

  Future<void> _handleEdit() async {
    final stock = widget.initialStock;
    if (stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Initial stock data not available for edit yet.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddStockScreen(initialStock: stock)),
    );
  }

  Future<void> _openGalleryManager() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StockGalleryScreen(
          stockId: widget.stockId,
          title: widget.initialStock?.displayTitle ?? _detail?.stock.stockNumber ?? 'Stock',
          registration:
              widget.initialStock?.displayRegistration ??
              _detail?.vehicle.registrationNumber ??
              _detail?.stock.stockNumber ??
              'STOCK',
        ),
      ),
    );

    if (updated == true && mounted) {
      _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFFACC14);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandYellow))
          : _detail == null
          ? _buildErrorState()
          : CustomScrollView(
              slivers: [
                _buildAppBar(_detail!),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderChips(_detail!),
                        const SizedBox(height: 20),
                        _buildGallerySection(),
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: 'Vehicle Overview',
                          child: Column(
                            children: [
                              _detailRow(
                                'Registration',
                                _detail!.vehicle.registrationNumber ??
                                    widget.initialStock?.displayRegistration ??
                                    _detail!.stock.stockNumber,
                              ),
                              _detailRow(
                                'Make',
                                _detail!.vehicle.make ?? widget.initialStock?.make ?? 'Not available',
                              ),
                              _detailRow(
                                'Model',
                                _detail!.vehicle.model ?? widget.initialStock?.model ?? 'Not available',
                              ),
                              _detailRow('Variant', _detail!.vehicle.variant ?? 'Not available'),
                              _detailRow(
                                'Year',
                                _detail!.vehicle.registrationYear?.toString() ?? 'Not available',
                              ),
                              _detailRow(
                                'Mileage',
                                _detail!.vehicle.mileage == null
                                    ? 'Not available'
                                    : "${_detail!.vehicle.mileage} miles",
                              ),
                              _detailRow('Colour', _detail!.vehicle.colour ?? 'Not available'),
                              _detailRow('Body Type', _detail!.vehicle.bodyType ?? 'Not available'),
                              _detailRow('Fuel', _detail!.vehicle.fuelType ?? 'Not available'),
                              _detailRow(
                                'Transmission',
                                _detail!.vehicle.transmission ?? 'Not available',
                              ),
                              _detailRow(
                                'Previous Owners',
                                _detail!.vehicle.previousOwners?.toString() ?? 'Not available',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _DetailSection(
                          title: 'Inventory Meta',
                          child: Column(
                            children: [
                              _detailRow('Stock Number', _detail!.stock.stockNumber),
                              _detailRow('Status', _currentStatus),
                              _detailRow('Source', _detail!.stock.sourceType),
                              _detailRow(
                                'Ask Price',
                                _detail!.stock.askPrice == null
                                    ? 'Not available'
                                    : "${_detail!.stock.currencyCode} ${_detail!.stock.askPrice!.toStringAsFixed(0)}",
                              ),
                              _detailRow(
                                'Visible In API',
                                _detail!.stock.isVisibleInApi ? 'Yes' : 'No',
                              ),
                              _detailRow(
                                'Linked Lead',
                                _detail!.summary.hasLinkedLead ? 'Yes' : 'No',
                              ),
                              _detailRow(
                                'Image Count',
                                _detail!.summary.imageCount.toString(),
                              ),
                              _detailRow(
                                'Created',
                                _formatDateTime(_detail!.stock.createdAt.toLocal()),
                              ),
                            ],
                          ),
                        ),
                        if ((_detail!.vehicle.description ?? '').isNotEmpty ||
                            (_detail!.vehicle.conditionNotes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _DetailSection(
                            title: 'Notes',
                            child: Text(
                              _detail!.vehicle.description ??
                                  _detail!.vehicle.conditionNotes ??
                                  '',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _detail == null
          ? null
          : _StockActionBar(
              status: _currentStatus,
              canEdit: _canEdit,
              onChangeStatus: _showChangeStatusSheet,
              onBroadcast: _handleBroadcast,
              onEdit: _handleEdit,
            ),
    );
  }

  SliverAppBar _buildAppBar(StockDetailModel detail) {
    const brandYellow = Color(0xFFFACC14);
    final vehicleTitle = [
      if (detail.vehicle.registrationYear != null)
        detail.vehicle.registrationYear.toString(),
      detail.vehicle.make ?? widget.initialStock?.make,
      detail.vehicle.model ?? widget.initialStock?.model,
    ].whereType<String>().where((e) => e.isNotEmpty).join(' ');

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: brandYellow,
      foregroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _galleryController,
              onPageChanged: (index) => setState(() => _activeImageIndex = index),
              itemCount: _galleryImages.length,
              itemBuilder: (context, index) => Image.network(
                _galleryImages[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.52),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UkRegPlate(
                    reg: detail.vehicle.registrationNumber ??
                        widget.initialStock?.displayRegistration ??
                        detail.stock.stockNumber,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vehicleTitle.isEmpty ? detail.stock.stockNumber : vehicleTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        detail.stock.askPrice == null
                            ? detail.stock.stockNumber
                            : "${detail.stock.currencyCode} ${detail.stock.askPrice!.toStringAsFixed(0)}",
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC14).withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _currentStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderChips(StockDetailModel detail) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InfoChip(label: 'Status', value: _currentStatus),
        _InfoChip(
          label: 'Stock Number',
          value: detail.stock.stockNumber,
          backgroundColor: const Color(0xFFFACC14).withValues(alpha: 0.2),
        ),
        _InfoChip(
          label: 'Images',
          value: "${detail.summary.imageCount}",
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    return _DetailSection(
      title: 'Gallery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _galleryImages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isActive = index == _activeImageIndex;
                return GestureDetector(
                  onTap: () {
                    _galleryController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    width: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFFACC14)
                            : Colors.grey.shade200,
                        width: isActive ? 2 : 1,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(_galleryImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  "${_activeImageIndex + 1} of ${_galleryImages.length} images",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openGalleryManager,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Manage Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: const Color(0xFFFACC14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        const Icon(Icons.wifi_off_rounded, size: 46, color: Colors.grey),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: _loadDetail,
            child: const Text("Try Again"),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = _monthName(dateTime.month);
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return "${dateTime.day} $month ${dateTime.year}, $hour:$minute $suffix";
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _StockActionBar extends StatelessWidget {
  final String status;
  final bool canEdit;
  final VoidCallback onChangeStatus;
  final VoidCallback onBroadcast;
  final VoidCallback onEdit;

  const _StockActionBar({
    required this.status,
    required this.canEdit,
    required this.onChangeStatus,
    required this.onBroadcast,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onChangeStatus,
                    icon: const Icon(Icons.sync_alt),
                    label: Text(status == 'SOLD' ? 'Change Status' : 'Mark Sold / In Stock'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onBroadcast,
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Broadcast'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            if (canEdit) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Vehicle'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? backgroundColor;

  const _InfoChip({
    required this.label,
    required this.value,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
