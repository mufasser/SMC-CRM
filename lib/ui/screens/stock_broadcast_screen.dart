import 'package:flutter/material.dart';

import '../../data/models/stock_model.dart';
import '../../data/services/crm_service.dart';
import '../widgets/uk_reg_plate.dart';

class StockBroadcastScreen extends StatefulWidget {
  final String stockId;
  final String title;
  final String registration;

  const StockBroadcastScreen({
    super.key,
    required this.stockId,
    required this.title,
    required this.registration,
  });

  @override
  State<StockBroadcastScreen> createState() => _StockBroadcastScreenState();
}

class _StockBroadcastScreenState extends State<StockBroadcastScreen> {
  final CRMService _crmService = CRMService();

  StockBroadcastData? _data;
  Set<String> _selectedProviderKeys = <String>{};
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _didUpdateBroadcast = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBroadcasts();
  }

  Future<void> _loadBroadcasts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await _crmService.fetchStockBroadcasts(widget.stockId);

    if (!mounted) {
      return;
    }

    if (data == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load broadcasters right now.';
      });
      return;
    }

    final readyBroadcasters = data.broadcasters.where((item) => item.isReady);
    final availableKeys = readyBroadcasters.map((item) => item.key).toSet();
    final preservedSelection = _selectedProviderKeys
        .where(availableKeys.contains)
        .toSet();
    final defaultSelection = readyBroadcasters.map((item) => item.key).toSet();

    setState(() {
      _data = data;
      _selectedProviderKeys = preservedSelection.isEmpty
          ? defaultSelection
          : preservedSelection;
      _isLoading = false;
    });
  }

  List<StockBroadcaster> get _broadcasters {
    final broadcasters = List<StockBroadcaster>.from(
      (_data?.broadcasters ?? const <StockBroadcaster>[])
          .where((item) => item.isReady),
    )..sort((a, b) => a.displayName.compareTo(b.displayName));
    return broadcasters;
  }

  int get _readyCount => _broadcasters.where((item) => item.isReady).length;

  int get _publishedCount => _broadcasters
      .where((item) => item.syncState?.isPublished == true)
      .length;

  String get _currentStatus =>
      _data?.stockVehicle.stockStatus.toUpperCase() ?? 'IN_STOCK';

  List<String> get _selectedReadyKeys => _broadcasters
      .where((item) => _selectedProviderKeys.contains(item.key) && item.isReady)
      .map((item) => item.key)
      .toList();

  bool get _hasSelection => _selectedReadyKeys.isNotEmpty;

  void _toggleProvider(StockBroadcaster broadcaster) {
    if (!broadcaster.isReady) {
      return;
    }

    setState(() {
      if (_selectedProviderKeys.contains(broadcaster.key)) {
        _selectedProviderKeys.remove(broadcaster.key);
      } else {
        _selectedProviderKeys.add(broadcaster.key);
      }
    });
  }

  void _toggleSelectAll() {
    final readyKeys = _broadcasters
        .where((item) => item.isReady)
        .map((item) => item.key)
        .toSet();
    if (readyKeys.isEmpty) {
      return;
    }

    setState(() {
      if (_selectedProviderKeys.length == readyKeys.length &&
          _selectedProviderKeys.containsAll(readyKeys)) {
        _selectedProviderKeys.clear();
      } else {
        _selectedProviderKeys = readyKeys;
      }
    });
  }

  void _showSelectionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select at least one ready broadcaster first.'),
      ),
    );
  }

  Future<void> _pushSelected() async {
    if (!_hasSelection) {
      _showSelectionMessage();
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await _crmService.pushStockToBroadcasters(
      stockId: widget.stockId,
      providerKeys: _selectedReadyKeys,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    _didUpdateBroadcast = _didUpdateBroadcast || response['success'] == true;

    await _showResultSheet(
      title: 'Broadcast Result',
      message:
          response['message']?.toString() ?? 'Broadcaster sync completed.',
      results: (response['results'] as List?) ?? const [],
    );

    if (response['success'] == true) {
      await _loadBroadcasts();
    }
  }

  Future<void> _changeStockStatus(String nextStatus) async {
    if (!_hasSelection) {
      _showSelectionMessage();
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await _crmService.updateBroadcastStockStatus(
      stockId: widget.stockId,
      stockStatus: nextStatus,
      providerKeys: _selectedReadyKeys,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    _didUpdateBroadcast = _didUpdateBroadcast || response['success'] == true;

    await _showResultSheet(
      title: nextStatus == 'OUT_OF_STOCK'
          ? 'Marked Out Of Stock'
          : 'Marked In Stock',
      message:
          response['message']?.toString() ??
          'Stock status updated successfully.',
      results: (response['broadcasterResults'] as List?) ?? const [],
    );

    if (response['success'] == true) {
      await _loadBroadcasts();
    }
  }

  Future<void> _openPriceSheet() async {
    final currentPrice = _data?.stockVehicle.askPrice;
    final draft = await showModalBottomSheet<_PriceDraft>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PriceSheet(
        initialPrice: currentPrice,
        currencyCode: 'GBP',
      ),
    );

    if (draft == null || !_hasSelection) {
      if (draft != null && !_hasSelection) {
        _showSelectionMessage();
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await _crmService.updateBroadcastStockPrice(
      stockId: widget.stockId,
      askPrice: draft.askPrice,
      providerKeys: _selectedReadyKeys,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    _didUpdateBroadcast = _didUpdateBroadcast || response['success'] == true;

    await _showResultSheet(
      title: 'Price Updated',
      message:
          response['message']?.toString() ??
          'Stock price updated successfully.',
      results: (response['broadcasterResults'] as List?) ?? const [],
    );

    if (response['success'] == true) {
      await _loadBroadcasts();
    }
  }

  Future<void> _showResultSheet({
    required String title,
    required String message,
    required List results,
  }) async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ActionResultSheet(
        title: title,
        message: message,
        results: results,
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
        Navigator.pop(context, _didUpdateBroadcast);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F6F1),
        appBar: AppBar(
          backgroundColor: brandYellow,
          foregroundColor: brandBlack,
          title: const Text(
            'Broadcast Vehicle',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: _broadcasters.isEmpty || _isSubmitting
                  ? null
                  : _toggleSelectAll,
              child: Text(
                _selectedProviderKeys.length == _readyCount && _readyCount > 0
                    ? 'Clear'
                    : 'Select',
                style: const TextStyle(
                  color: brandBlack,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: brandYellow))
            : _errorMessage != null
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _loadBroadcasts,
                color: Colors.black,
                backgroundColor: brandYellow,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 16),
                            _buildQuickHelpStrip(),
                            const SizedBox(height: 16),
                            _buildSummaryStrip(),
                            const SizedBox(height: 18),
                            _buildSectionHeader(
                              title: 'Broadcasters',
                              subtitle:
                                  'Pick where this stock should be live right now.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_broadcasters.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: _buildEmptyBroadcastersCard(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverList.separated(
                          itemCount: _broadcasters.length,
                          itemBuilder: (context, index) {
                            final broadcaster = _broadcasters[index];
                            return _BroadcasterCard(
                              broadcaster: broadcaster,
                              isSelected: _selectedProviderKeys.contains(
                                broadcaster.key,
                              ),
                              onTap: () => _toggleProvider(broadcaster),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: _buildSectionHeader(
                          title: 'Sync Logs',
                          subtitle:
                              'Latest publish activity for this stock vehicle.',
                        ),
                      ),
                    ),
                    if ((_data?.logs ?? const []).isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                          child: _buildEmptyLogsCard(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                        sliver: SliverList.separated(
                          itemCount: _data!.logs.length,
                          itemBuilder: (context, index) => _LogCard(
                            log: _data!.logs[index],
                          ),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                        ),
                      ),
                  ],
                ),
              ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _hasSelection
                                ? '${_selectedReadyKeys.length} broadcaster${_selectedReadyKeys.length == 1 ? '' : 's'} selected'
                                : 'No ready broadcaster selected',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentStatus == 'IN_STOCK'
                                ? 'Push live, sync price, or mark sold.'
                                : 'Bring this vehicle back into stock and sync it.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _pushSelected,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlack,
                        foregroundColor: brandYellow,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: brandYellow,
                              ),
                            )
                          : const Icon(Icons.campaign_outlined),
                      label: Text(_isSubmitting ? 'Working...' : 'Push'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _openPriceSheet,
                        icon: const Icon(Icons.currency_pound_outlined),
                        label: const Text('Update Price'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _changeStockStatus(
                                _currentStatus == 'IN_STOCK'
                                    ? 'OUT_OF_STOCK'
                                    : 'IN_STOCK',
                              ),
                        icon: Icon(
                          _currentStatus == 'IN_STOCK'
                              ? Icons.sell_outlined
                              : Icons.inventory_2_outlined,
                        ),
                        label: Text(
                          _currentStatus == 'IN_STOCK'
                              ? 'Mark Sold'
                              : 'Mark In Stock',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandYellow,
                          foregroundColor: brandBlack,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    const brandYellow = Color(0xFFFACC14);
    final vehicle = _data!.stockVehicle;
    final price = vehicle.askPrice == null
        ? 'Price not set'
        : '${_currencySymbol('GBP')}${vehicle.askPrice!.toStringAsFixed(0)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD84D), Color(0xFFF4BF18)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _data!.stockVehicle.displayTitle == widget.stockId
                      ? widget.title
                      : _data!.stockVehicle.displayTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatStatusLabel(_currentStatus),
                  style: const TextStyle(
                    color: brandYellow,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          UkRegPlate(
            reg: _data!.stockVehicle.registrationNumber ?? widget.registration,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Asking Price',
                  value: price,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Ready Broadcasters',
                  value: '$_readyCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelpStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        'Choose broadcasters, then push the vehicle, sync a new price, or mark it sold.',
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildSummaryStrip() {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Selected',
            value: '${_selectedReadyKeys.length}',
            icon: Icons.checklist_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: 'Published',
            value: '$_publishedCount',
            icon: Icons.public_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryTile(
            label: 'Logs',
            value: '${_data!.logs.length}',
            icon: Icons.history_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyBroadcastersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.campaign_outlined,
            size: 36,
            color: Colors.black54,
          ),
          const SizedBox(height: 12),
          const Text(
            'No broadcasters available',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Once broadcasters are configured for this dealer, they will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLogsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        'No sync logs yet for this vehicle.',
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
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
            onPressed: _loadBroadcasts,
            child: const Text('Try Again'),
          ),
        ),
      ],
    );
  }

  String _currencySymbol(String currencyCode) {
    return currencyCode.toUpperCase() == 'GBP' ? '£' : currencyCode;
  }
}

class _BroadcasterCard extends StatelessWidget {
  final StockBroadcaster broadcaster;
  final bool isSelected;
  final VoidCallback onTap;

  const _BroadcasterCard({
    required this.broadcaster,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final published = broadcaster.syncState?.isPublished == true;
    final syncLabel = _formatStatusLabel(
      broadcaster.syncState?.syncStatus ?? 'NOT_SYNCED',
    );
    final lastSynced = broadcaster.syncState?.lastSyncedAt;
    final lastError = broadcaster.syncState?.lastErrorAt;
    final isReady = broadcaster.isReady;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? const Color(0xFFFACC14) : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isReady
                          ? const Color(0xFFFACC14).withValues(alpha: 0.18)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      broadcaster.logoText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          broadcaster.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          broadcaster.websiteUrl ?? broadcaster.shortName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected
                        ? const Color(0xFFFACC14)
                        : isReady
                        ? Colors.black54
                        : Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusBadge(
                    label: _formatStatusLabel(broadcaster.healthStatus),
                    backgroundColor: isReady
                        ? const Color(0xFFD8F4DE)
                        : const Color(0xFFF3F4F6),
                    foregroundColor: isReady
                        ? const Color(0xFF166534)
                        : Colors.black87,
                  ),
                  _StatusBadge(
                    label: _formatStatusLabel(broadcaster.effectiveConnectionMode),
                    backgroundColor: const Color(0xFFF5F1D6),
                    foregroundColor: Colors.black87,
                  ),
                  _StatusBadge(
                    label: published ? 'Published' : 'Not Published',
                    backgroundColor: published
                        ? const Color(0xFFE2F0FF)
                        : const Color(0xFFF3F4F6),
                    foregroundColor: published
                        ? const Color(0xFF1D4ED8)
                        : Colors.black87,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetaItem(
                      label: 'Auto Sync',
                      value: broadcaster.autoSyncEnabled ? 'On' : 'Off',
                    ),
                  ),
                  Expanded(
                    child: _MetaItem(
                      label: 'Sync State',
                      value: syncLabel,
                    ),
                  ),
                  Expanded(
                    child: _MetaItem(
                      label: 'Listing ID',
                      value:
                          broadcaster.syncState?.externalListingId ?? 'Not set',
                    ),
                  ),
                ],
              ),
              if (lastSynced != null || lastError != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lastSynced != null)
                        Text(
                          'Last synced ${_formatDateTime(lastSynced.toLocal())}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      if (lastError != null) ...[
                        if (lastSynced != null) const SizedBox(height: 6),
                        Text(
                          broadcaster.syncState?.lastErrorMessage ??
                              'Last sync reported an error.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (!isReady) ...[
                        const SizedBox(height: 6),
                        Text(
                          broadcaster.isEnabledByDealer
                              ? 'This broadcaster is not ready yet.'
                              : 'Dealer has not enabled this broadcaster.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final StockBroadcastLog log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final success = (log.responseStatus ?? 0) >= 200 &&
        (log.responseStatus ?? 0) < 300;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatStatusLabel(log.providerKey),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _StatusBadge(
                label: log.responseStatus?.toString() ?? 'N/A',
                backgroundColor: success
                    ? const Color(0xFFD8F4DE)
                    : const Color(0xFFFDE2E2),
                foregroundColor: success
                    ? const Color(0xFF166534)
                    : const Color(0xFF991B1B),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusBadge(
                label: log.requestMethod,
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: Colors.black87,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.requestUrl ?? 'No request URL saved',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
          if ((log.responseBody ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                log.responseBody!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (log.createdAt != null) ...[
            const SizedBox(height: 10),
            Text(
              _formatDateTime(log.createdAt!.toLocal()),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.64),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionResultSheet extends StatelessWidget {
  final String title;
  final String message;
  final List results;

  const _ActionResultSheet({
    required this.title,
    required this.message,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
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
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700], height: 1.4),
              ),
              if (results.isNotEmpty) ...[
                const SizedBox(height: 18),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final data = item is Map<String, dynamic>
                          ? item
                          : <String, dynamic>{};
                      final success = data['success'] == true;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F4),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              success
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color: success
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFB91C1C),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatStatusLabel(
                                      data['providerKey']?.toString() ??
                                          'Broadcaster',
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['message']?.toString() ??
                                        'Action completed.',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (data['responseStatus'] != null)
                              Text(
                                data['responseStatus'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceDraft {
  final double askPrice;

  const _PriceDraft({required this.askPrice});
}

class _PriceSheet extends StatefulWidget {
  final double? initialPrice;
  final String currencyCode;

  const _PriceSheet({
    required this.initialPrice,
    required this.currencyCode,
  });

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  late final TextEditingController _priceController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.initialPrice == null
          ? ''
          : widget.initialPrice!.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      _PriceDraft(askPrice: double.parse(_priceController.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
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
                  'Update Asking Price',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'This updates CRM stock first, then syncs the new price to selected broadcasters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], height: 1.4),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Asking Price',
                    prefixText: widget.currencyCode.toUpperCase() == 'GBP'
                        ? '£ '
                        : '${widget.currencyCode} ',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    final price = double.tryParse(text);
                    if (text.isEmpty) {
                      return 'Enter a price';
                    }
                    if (price == null || price <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: const Color(0xFFFACC14),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Update Price'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatStatusLabel(String value) {
  return value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
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
  return '${dateTime.day} $month ${dateTime.year}, $hour:$minute $suffix';
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
