import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/lead_model.dart';
import '../../data/services/crm_service.dart';
import '../widgets/uk_reg_plate.dart';

class LeadDetailScreen extends StatefulWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  final CRMService _crmService = CRMService();

  late LeadModel _lead;
  List<LeadStatusOption> _statusOptions = [];
  bool _isLoadingStatuses = true;
  bool _isUpdatingStatus = false;
  bool _didUpdateLead = false;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    _loadStatusOptions();
  }

  Future<void> _loadStatusOptions() async {
    final options = await _crmService.fetchLeadStatusOptions();

    if (!mounted) {
      return;
    }

    setState(() {
      _statusOptions = options;
      _isLoadingStatuses = false;
    });
  }

  Future<void> _openStatusSheet() async {
    if (_isLoadingStatuses || _statusOptions.isEmpty || _isUpdatingStatus) {
      return;
    }

    final selected = await showModalBottomSheet<LeadStatusOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LeadStatusSheet(
        currentStatus: _lead.pipelineStatus,
        options: _statusOptions,
      ),
    );

    if (selected == null || selected.value == _lead.pipelineStatus) {
      return;
    }

    setState(() => _isUpdatingStatus = true);

    final response = await _crmService.updateLeadStatus(
      leadId: _lead.id,
      pipelineStatus: selected.value,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isUpdatingStatus = false);

    if (response['success'] == true) {
      setState(() {
        _lead = _lead.copyWith(
          pipelineStatus:
              response['pipelineStatus']?.toString() ?? selected.value,
          updatedAt: DateTime.tryParse(response['updatedAt']?.toString() ?? ''),
        );
        _didUpdateLead = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'Lead status updated successfully.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['message']?.toString() ?? 'Unable to update lead status.',
        ),
      ),
    );
  }

  String get _currentStatusLabel {
    for (final option in _statusOptions) {
      if (option.value == _lead.pipelineStatus) {
        return option.label;
      }
    }
    return _fallbackStatusLabel(_lead.pipelineStatus);
  }

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFFACC14);
    final vehicleTitle = [
      if (_lead.vehicle.registrationYear != null)
        _lead.vehicle.registrationYear.toString(),
      _lead.vehicle.make,
      _lead.vehicle.model,
    ].join(' ');

    return PopScope<LeadModel?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, _didUpdateLead ? _lead : null);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: brandYellow,
              foregroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _lead.vehicle.imageUrl ?? 'https://via.placeholder.com/600',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.directions_car_filled,
                          size: 64,
                          color: Colors.grey,
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
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 14,
                      right: 16,
                      child: _LeadStatusOverlayChip(
                        label: _currentStatusLabel,
                        isLoading: _isLoadingStatuses,
                        isUpdating: _isUpdatingStatus,
                        onTap: _openStatusSheet,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          UkRegPlate(reg: _lead.vehicle.registrationNumber),
                          const SizedBox(height: 12),
                          Text(
                            vehicleTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${_lead.vehicle.mileage} miles",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoChip(
                          label: 'Valuation',
                          value:
                              "${_lead.valuationCurrency ?? '£'} ${_lead.valuationAmount ?? '0'}",
                        ),
                        _InfoChip(
                          label: 'Source',
                          value: _lead.sourceName.isEmpty
                              ? _lead.sourceType
                              : _lead.sourceName,
                        ),
                        _InfoChip(
                          label: 'Contact',
                          value:
                              _lead.preferredContactMethod?.replaceAll('_', ' ') ??
                              'Not set',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _DetailSection(
                      title: 'Customer',
                      child: Column(
                        children: [
                          _detailRow('Name', _lead.customer.fullName),
                          _detailRow('Phone', _lead.customer.phoneNumber),
                          _detailRow(
                            'WhatsApp',
                            _lead.customer.whatsappNumber ?? 'Not available',
                          ),
                          _detailRow(
                            'Email',
                            _lead.customer.email ?? 'Not available',
                          ),
                          _detailRow(
                            'Postcode',
                            _lead.customer.postcode ?? 'Not available',
                          ),
                          _detailRow(
                            'Best Time',
                            _lead.bestTimeToContact ?? 'Not set',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DetailSection(
                      title: 'Vehicle',
                      child: Column(
                        children: [
                          _detailRow(
                            'Registration',
                            _lead.vehicle.registrationNumber,
                          ),
                          _detailRow('Make', _lead.vehicle.make),
                          _detailRow('Model', _lead.vehicle.model),
                          _detailRow(
                            'Variant',
                            _lead.vehicle.variant ?? 'Not available',
                          ),
                          _detailRow(
                            'Year',
                            _lead.vehicle.registrationYear?.toString() ??
                                'Not available',
                          ),
                          _detailRow('Mileage', "${_lead.vehicle.mileage} miles"),
                          _detailRow(
                            'Colour',
                            _lead.vehicle.colour ?? 'Not available',
                          ),
                          _detailRow(
                            'Body Type',
                            _lead.vehicle.bodyType ?? 'Not available',
                          ),
                          _detailRow(
                            'Fuel',
                            _lead.vehicle.fuelType ?? 'Not available',
                          ),
                          _detailRow(
                            'Transmission',
                            _lead.vehicle.transmission ?? 'Not available',
                          ),
                          _detailRow(
                            'Previous Owners',
                            _lead.vehicle.previousOwners?.toString() ??
                                'Not available',
                          ),
                          _detailRow(
                            'Engine Capacity',
                            _lead.vehicle.engineCapacity ?? 'Not available',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DetailSection(
                      title: 'Lead Info',
                      child: Column(
                        children: [
                          _detailRow(
                            'Created',
                            _formatDateTime(_lead.createdAt.toLocal()),
                          ),
                          _detailRow(
                            'Updated',
                            _lead.updatedAt == null
                                ? 'Not available'
                                : _formatDateTime(_lead.updatedAt!.toLocal()),
                          ),
                          _detailRow(
                            'Enquiry Time',
                            _lead.enquiryTime == null
                                ? 'Not available'
                                : _formatDateTime(_lead.enquiryTime!.toLocal()),
                          ),
                          _detailRow(
                            'Offer Requested',
                            _lead.isOfferRequested ? 'Yes' : 'No',
                          ),
                          _detailRow(
                            'Published To Inventory',
                            _lead.isPublishedToInventory ? 'Yes' : 'No',
                          ),
                        ],
                      ),
                    ),
                    if ((_lead.extraNote ?? '').isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _DetailSection(
                        title: 'Notes',
                        child: Text(
                          _lead.extraNote!,
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
        bottomNavigationBar: _ActionBar(lead: _lead),
      ),
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

String _fallbackStatusLabel(String value) {
  return value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => "${word[0].toUpperCase()}${word.substring(1)}")
      .join(' ');
}

class _LeadStatusOverlayChip extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isUpdating;
  final VoidCallback onTap;

  const _LeadStatusOverlayChip({
    required this.label,
    required this.isLoading,
    required this.isUpdating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: isLoading || isUpdating ? null : onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFFACC14).withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUpdating)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFACC14),
                  ),
                )
              else ...[
                const Icon(
                  Icons.local_offer_outlined,
                  size: 16,
                  color: Color(0xFFFACC14),
                ),
                const SizedBox(width: 8),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  isLoading ? 'Loading...' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadStatusSheet extends StatelessWidget {
  final String currentStatus;
  final List<LeadStatusOption> options;

  const _LeadStatusSheet({
    required this.currentStatus,
    required this.options,
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
              const Text(
                'Change Lead Stage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick the stage that best reflects what is happening with this lead right now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isCurrent = option.value == currentStatus;

                    return Material(
                      color: isCurrent
                          ? const Color(0xFFFACC14).withValues(alpha: 0.2)
                          : const Color(0xFFF8F8F4),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: isCurrent ? null : () => Navigator.pop(context, option),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.black
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isCurrent
                                      ? Icons.check_rounded
                                      : Icons.flag_outlined,
                                  color: isCurrent
                                      ? const Color(0xFFFACC14)
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isCurrent
                                          ? 'Current stage'
                                          : 'Move lead into this stage',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                const Icon(
                                  Icons.radio_button_checked,
                                  color: Colors.black,
                                )
                              else
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final LeadModel lead;

  const _ActionBar({required this.lead});

  @override
  Widget build(BuildContext context) {
    final whatsappPhone =
        lead.customer.whatsappNumber ?? lead.customer.phoneNumber;
    final email = lead.customer.email;

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
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchWhatsApp(context, whatsappPhone, lead),
                icon: const Icon(Icons.message, color: Colors.white),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: Icons.phone_outlined,
              onTap: () => _launchUrl(
                context,
                Uri.parse("tel:${lead.customer.phoneNumber}"),
              ),
            ),
            const SizedBox(width: 10),
            _QuickActionButton(
              icon: Icons.email_outlined,
              onTap: email == null
                  ? null
                  : () => _launchUrl(context, Uri.parse("mailto:$email")),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchWhatsApp(
    BuildContext context,
    String phone,
    LeadModel lead,
  ) async {
    final cleanPhone = _sanitizePhone(phone);
    final text = Uri.encodeComponent(
      "Regarding your ${lead.vehicle.make} ${lead.vehicle.model}",
    );

    final directUri = Uri.parse("whatsapp://send?phone=$cleanPhone&text=$text");
    final webUri = Uri.parse("https://wa.me/$cleanPhone?text=$text");

    final launchedDirect = await launchUrl(directUri);
    if (launchedDirect) {
      return;
    }

    if (!context.mounted) {
      return;
    }
    await _launchUrl(context, webUri, mode: LaunchMode.externalApplication);
  }

  static Future<void> _launchUrl(
    BuildContext context,
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    final launched = await launchUrl(uri, mode: mode);
    if (!context.mounted) {
      return;
    }
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this action right now.')),
      );
    }
  }

  static String _sanitizePhone(String value) {
    var clean = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('0')) {
      clean = '44${clean.substring(1)}';
    }
    if (!clean.startsWith('44') &&
        !clean.startsWith('+44') &&
        !clean.startsWith('+')) {
      clean = '44$clean';
    }
    return clean.replaceAll('+', '');
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

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuickActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          width: 52,
          child: Icon(icon, color: onTap == null ? Colors.grey : Colors.black),
        ),
      ),
    );
  }
}
