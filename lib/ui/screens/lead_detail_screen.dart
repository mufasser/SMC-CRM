import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/lead_model.dart';
import '../widgets/uk_reg_plate.dart';

class LeadDetailScreen extends StatelessWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFFACC14);
    final vehicleTitle = [
      if (lead.vehicle.registrationYear != null)
        lead.vehicle.registrationYear.toString(),
      lead.vehicle.make,
      lead.vehicle.model,
    ].join(' ');

    return Scaffold(
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
                    lead.vehicle.imageUrl ?? 'https://via.placeholder.com/600',
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
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        UkRegPlate(reg: lead.vehicle.registrationNumber),
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
                          "${lead.vehicle.mileage} miles",
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
                        label: 'Status',
                        value: lead.pipelineStatus.replaceAll('_', ' '),
                        backgroundColor: brandYellow.withValues(alpha: 0.2),
                      ),
                      _InfoChip(
                        label: 'Valuation',
                        value:
                            "${lead.valuationCurrency ?? '£'} ${lead.valuationAmount ?? '0'}",
                      ),
                      _InfoChip(
                        label: 'Source',
                        value: lead.sourceName.isEmpty
                            ? lead.sourceType
                            : lead.sourceName,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _DetailSection(
                    title: 'Customer',
                    child: Column(
                      children: [
                        _detailRow('Name', lead.customer.fullName),
                        _detailRow('Phone', lead.customer.phoneNumber),
                        _detailRow(
                          'WhatsApp',
                          lead.customer.whatsappNumber ?? 'Not available',
                        ),
                        _detailRow(
                          'Email',
                          lead.customer.email ?? 'Not available',
                        ),
                        _detailRow(
                          'Postcode',
                          lead.customer.postcode ?? 'Not available',
                        ),
                        _detailRow(
                          'Preferred Contact',
                          lead.preferredContactMethod ?? 'Not set',
                        ),
                        _detailRow(
                          'Best Time',
                          lead.bestTimeToContact ?? 'Not set',
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
                          lead.vehicle.registrationNumber,
                        ),
                        _detailRow('Make', lead.vehicle.make),
                        _detailRow('Model', lead.vehicle.model),
                        _detailRow(
                          'Variant',
                          lead.vehicle.variant ?? 'Not available',
                        ),
                        _detailRow(
                          'Year',
                          lead.vehicle.registrationYear?.toString() ??
                              'Not available',
                        ),
                        _detailRow('Mileage', "${lead.vehicle.mileage} miles"),
                        _detailRow(
                          'Colour',
                          lead.vehicle.colour ?? 'Not available',
                        ),
                        _detailRow(
                          'Body Type',
                          lead.vehicle.bodyType ?? 'Not available',
                        ),
                        _detailRow(
                          'Fuel',
                          lead.vehicle.fuelType ?? 'Not available',
                        ),
                        _detailRow(
                          'Transmission',
                          lead.vehicle.transmission ?? 'Not available',
                        ),
                        _detailRow(
                          'Previous Owners',
                          lead.vehicle.previousOwners?.toString() ??
                              'Not available',
                        ),
                        _detailRow(
                          'Engine Capacity',
                          lead.vehicle.engineCapacity ?? 'Not available',
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
                          _formatDateTime(lead.createdAt.toLocal()),
                        ),
                        _detailRow(
                          'Enquiry Time',
                          lead.enquiryTime == null
                              ? 'Not available'
                              : _formatDateTime(lead.enquiryTime!.toLocal()),
                        ),
                        _detailRow(
                          'Offer Requested',
                          lead.isOfferRequested ? 'Yes' : 'No',
                        ),
                        _detailRow(
                          'Published To Inventory',
                          lead.isPublishedToInventory ? 'Yes' : 'No',
                        ),
                      ],
                    ),
                  ),
                  if ((lead.extraNote ?? '').isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _DetailSection(
                      title: 'Notes',
                      child: Text(
                        lead.extraNote!,
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
      bottomNavigationBar: _ActionBar(lead: lead),
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
                onPressed: () => _launchWhatsApp(context, whatsappPhone),
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

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
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

  Future<void> _launchUrl(
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
