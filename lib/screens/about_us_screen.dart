import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // (عشان التليفون والإيميل)

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // 1. دالة مساعدة عشان تفتح اللينكات
  Future<void> _launch(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن فتح هذا الرابط: $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('من نحن')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. النص التعريفي
            const Text(
              "تطبيق صحتي يسهّل على الجالية اليمنية والعربية الوصول إلى أفضل الخدمات الطبية من خلال دليل شامل لأطباء ومستشفيات موثوق بها بالإضافة إلى إمكانية حجز المواعيد وإجراء العمليات بسهولة ويسر.",
              style: TextStyle(
                fontSize: 16.5,
                height: 1.6, // (مسافة بين السطور)
                color: Color(0xFF333333),
              ),
            ),
            const Divider(height: 40),

            // 3. قسم التواصل
            Text(
              "للتواصل",
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 4. زرار التليفون
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.phone_outlined,
                color: Colors.blue.shade700,
                size: 30,
              ),
              title: const Text(
                '+966563942497',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              onTap: () => _launch('tel:+966563942497', context),
            ),

            // 5. زرار الإيميل
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.email_outlined,
                color: Colors.blue.shade700,
                size: 30,
              ),
              title: const Text(
                'info@sehetie.com',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              onTap: () => _launch('mailto:info@sehetie.com', context),
            ),
          ],
        ),
      ),
    );
  }
}
