import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add to pubspec: flutter pub add url_launcher

class CustomerInfoCard extends StatelessWidget {
  final String name;
  final String phone;
  final String email;

  const CustomerInfoCard({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Customer Information",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(height: 30),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(name),
              subtitle: Text(email),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(
                  Icons.phone,
                  "Call",
                  Colors.green,
                  () => _launchCaller(phone),
                ),
                _actionButton(
                  Icons.message,
                  "WhatsApp",
                  Colors.teal,
                  () => _launchWhatsApp(phone),
                ),
                _actionButton(
                  Icons.email,
                  "Email",
                  Colors.blue,
                  () => _launchEmail(email),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Logic to trigger phone/apps
  void _launchCaller(String p) async => await launchUrl(Uri.parse("tel:$p"));
  void _launchWhatsApp(String p) async =>
      await launchUrl(Uri.parse("https://wa.me/$p"));
  void _launchEmail(String e) async => await launchUrl(Uri.parse("mailto:$e"));
}
