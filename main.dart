import 'package:flutter/material.dart';

void main() => runApp(const AsgariHomeApp());

const gold = Color(0xFFD4AF37);
const black = Color(0xFF111111);

class AsgariHomeApp extends StatelessWidget {
  const AsgariHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'املاک عسگری',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
        colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.light),
        appBarTheme: const AppBarTheme(backgroundColor: black, foregroundColor: gold),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('املاک عسگری')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: black, borderRadius: BorderRadius.circular(18)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ASGARI HOME', style: TextStyle(color: gold, fontSize: 13, letterSpacing: 2)),
                SizedBox(height: 10),
                Text('خانه‌ی مناسب خود را پیدا کنید', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('خرید و فروش • رهن و اجاره', style: TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 22),
            const Text('دسترسی سریع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ActionTile(icon: Icons.home_work_outlined, title: 'مشاهده آگهی‌ها', subtitle: 'فایل‌های منتشرشده املاک'),
            _ActionTile(icon: Icons.search, title: 'جست‌وجوی ملک', subtitle: 'جست‌وجو بر اساس نوع و مشخصات'),
            _ActionTile(icon: Icons.admin_panel_settings_outlined, title: 'ورود مدیران', subtitle: 'بخش خصوصی مدیریت دفتر'),
            const SizedBox(height: 20),
            const Text('ارتباط با املاک عسگری', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const SelectableText('تماس: 09363882379\nتلگرام: @amlak_asgari'),
            const SizedBox(height: 20),
            const Text('نسخه اولیه نمایشی است؛ برای فعال شدن آگهی‌ها، ورود مدیران و همگام‌سازی آنلاین باید پایگاه داده و احراز هویت متصل شوند.',
              style: TextStyle(color: Colors.black54, height: 1.7)),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFFB18A16), size: 30),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left),
    ),
  );
}
