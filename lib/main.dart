
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

const String officePhone = '09363882379';

const Color gold = Color(0xFFD4AF37);
const Color black = Color(0xFF151515);
const Color backgroundColor = Color(0xFFF5F5F5);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool configured = false;

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      configured = true;
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
    }
  }

  runApp(AsgariApp(configured: configured));
}

class AsgariApp extends StatelessWidget {
  final bool configured;

  const AsgariApp({super.key, required this.configured});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASGARI HOME',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(seedColor: gold),
        appBarTheme: const AppBarTheme(
          backgroundColor: black,
          foregroundColor: gold,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      home: configured ? const HomePage() : const SetupNotice(),
    );
  }
}

class SetupNotice extends StatelessWidget {
  const SetupNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'تنظیمات اتصال به پایگاه داده کامل نیست.\n'
            'لطفاً تنظیمات GitHub Secrets را بررسی کنید.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17),
          ),
        ),
      ),
    );
  }
}

// -------------------- HOME --------------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'املاک عسگری',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'مدیریت',
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminGate()),
                );
              },
            ),
          ],
        ),
        body: const PublicListings(),
        bottomNavigationBar: Container(
          color: black,
          padding: const EdgeInsets.all(14),
          child: const Text(
            'املاک عسگری نهاوند | خرید، فروش، رهن و اجاره',
            textAlign: TextAlign.center,
            style: TextStyle(color: gold, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// -------------------- PUBLIC LISTINGS --------------------

class PublicListings extends StatefulWidget {
  const PublicListings({super.key});

  @override
  State<PublicListings> createState() => _PublicListingsState();
}

class _PublicListingsState extends State<PublicListings> {
  late Future<List<Map<String, dynamic>>> listingsFuture;

  String searchText = '';
  String selectedCategory = 'همه';

  @override
  void initState() {
    super.initState();
    listingsFuture = loadListings();
  }

  Future<List<Map<String, dynamic>>> loadListings() async {
    final response = await Supabase.instance.client
        .from('public_listings')
        .select()
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> refreshListings() async {
    final future = loadListings();
    setState(() {
      listingsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: black,
          child: const Column(
            children: [
              Icon(Icons.home_work, color: gold, size: 42),
              SizedBox(height: 10),
              Text(
                'به املاک عسگری خوش آمدید',
                style: TextStyle(
                  color: gold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'مشاور مطمئن معاملات ملکی شما در نهاوند',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              hintText: 'جستجوی ملک یا محله...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                searchText = value.trim();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              categoryButton('همه'),
              const SizedBox(width: 8),
              categoryButton('فروش'),
              const SizedBox(width: 8),
              categoryButton('رهن و اجاره'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: listingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: gold),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('دریافت اطلاعات با مشکل مواجه شد.'),
                      TextButton(
                        onPressed: refreshListings,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                );
              }

              final allListings = snapshot.data ?? [];

              final filtered = allListings.where((item) {
                final title = (item['title'] ?? '').toString();
                final neighborhood =
                    (item['neighborhood'] ?? '').toString();
                final category = (item['category'] ?? '').toString();

                final matchesSearch = searchText.isEmpty ||
                    title.contains(searchText) ||
                    neighborhood.contains(searchText);

                final matchesCategory = selectedCategory == 'همه' ||
                    category == selectedCategory;

                return matchesSearch && matchesCategory;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('در حال حاضر آگهی‌ای برای نمایش وجود ندارد.'),
                );
              }

              return RefreshIndicator(
                onRefresh: refreshListings,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return ListingCard(item: filtered[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget categoryButton(String category) {
    final selected = selectedCategory == category;

    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? black : Colors.white,
          foregroundColor: selected ? gold : black,
          side: const BorderSide(color: gold),
        ),
        onPressed: () {
          setState(() {
            selectedCategory = category;
          });
        },
        child: Text(category, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

// -------------------- LISTING CARD --------------------

class ListingCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const ListingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? 'ملک بدون عنوان';
    final category = item['category']?.toString() ?? '';
    final type = item['property_type']?.toString() ?? '';
    final area = item['area']?.toString() ?? '';
    final neighborhood = item['neighborhood']?.toString() ?? '';
    final price = item['display_price']?.toString() ?? '';

    final images = item['image_urls'] is List
        ? List<String>.from(item['image_urls'])
        : <String>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: gold, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailsPage(item: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isNotEmpty)
                SizedBox(
                  height: 190,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Image.network(
                          images[index],
                          width: 260,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 260,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.home_work,
                    size: 55,
                    color: Colors.grey,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Text('نوع معامله: $category'),
              if (type.isNotEmpty) Text('نوع ملک: $type'),
              if (area.isNotEmpty) Text('متراژ: $area متر'),
              if (neighborhood.isNotEmpty) Text('محله: $neighborhood'),
              if (price.isNotEmpty)
                Text(
                  'قیمت: $price',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.verified_user, color: gold, size: 18),
                  const SizedBox(width: 5),
                  const Expanded(
                    child: Text(
                      'املاک عسگری نهاوند',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    'مشاهده جزئیات',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios, size: 13),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- LISTING DETAILS --------------------

class ListingDetailsPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const ListingDetailsPage({super.key, required this.item});

  Future<void> callOffice(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: officePhone);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('امکان برقراری تماس وجود ندارد.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در باز کردن شماره تماس.')),
        );
      }
    }
  }

  Widget detailRow(IconData icon, String label, String value) {
    if (value.isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 21),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = item['image_urls'] is List
        ? List<String>.from(item['image_urls'])
        : <String>[];

    final title = item['title']?.toString() ?? 'ملک بدون عنوان';
    final category = item['category']?.toString() ?? '';
    final propertyType = item['property_type']?.toString() ?? '';
    final area = item['area']?.toString() ?? '';
    final neighborhood = item['neighborhood']?.toString() ?? '';
    final address = item['full_address']?.toString() ?? '';
    final bedrooms = item['bedrooms']?.toString() ?? '';
    final floor = item['floor_number']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final displayPrice = item['display_price']?.toString() ?? '';
    final salePrice = item['sale_price']?.toString() ?? '';
    final deposit = item['deposit_amount']?.toString() ?? '';
    final rent = item['monthly_rent']?.toString() ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('جزئیات ملک')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            if (images.isNotEmpty)
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.black,
                            child: InteractiveViewer(
                              child: Image.network(
                                images[index],
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Image.network(
                        images[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 220,
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.home_work,
                  size: 70,
                  color: Colors.grey,
                ),
              ),
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${images.length} تصویر - برای مشاهده تصاویر دیگر ورق بزنید',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      displayPrice.isNotEmpty
                          ? displayPrice
                          : category == 'فروش'
                              ? (salePrice.isNotEmpty
                                  ? '$salePrice تومان'
                                  : 'قیمت توافقی')
                              : 'رهن: ${deposit.isEmpty ? 'توافقی' : '$deposit تومان'}'
                                  ' | اجاره: ${rent.isEmpty ? 'توافقی' : '$rent تومان'}',
                      style: const TextStyle(
                        color: gold,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'مشخصات ملک',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  detailRow(Icons.swap_horiz, 'نوع معامله', category),
                  detailRow(Icons.home_work, 'نوع ملک', propertyType),
                  detailRow(
                    Icons.square_foot,
                    'متراژ',
                    area.isEmpty ? '' : '$area متر',
                  ),
                  detailRow(Icons.bed, 'تعداد اتاق خواب', bedrooms),
                  detailRow(Icons.layers, 'طبقه', floor),
                  detailRow(Icons.location_city, 'محله', neighborhood),
                  detailRow(Icons.location_on, 'آدرس', address),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'توضیحات ملک',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 15, height: 1.8),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gold),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.verified_user, color: gold, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'املاک عسگری نهاوند',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('مشاور مطمئن معاملات ملکی شما'),
                        SizedBox(height: 4),
                        Text(
                          officePhone,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: black,
                        foregroundColor: gold,
                      ),
                      onPressed: () => callOffice(context),
                      icon: const Icon(Icons.phone),
                      label: const Text(
                        'تماس با املاک عسگری',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- ADMIN LOGIN --------------------

class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String errorMessage = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'ایمیل و رمز عبور را وارد کنید.';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      final response = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      final user = response.user;

      if (user == null) {
        throw Exception('ورود انجام نشد.');
      }

      final membership = await Supabase.instance.client
          .from('admin_users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (membership == null) {
        await Supabase.instance.client.auth.signOut();
        throw Exception('این حساب دسترسی مدیریت ندارد.');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'خطا در ورود: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ورود مدیران')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 75,
                    color: gold,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'پنل مدیریت املاک عسگری',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'ایمیل مدیر',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'رمز عبور',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    onSubmitted: (_) => login(),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: black,
                        foregroundColor: gold,
                      ),
                      onPressed: loading ? null : login,
                      child: loading
                          ? const CircularProgressIndicator(color: gold)
                          : const Text('ورود به پنل مدیریت'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- ADMIN DASHBOARD --------------------

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<List<Map<String, dynamic>>> listingsFuture;

  @override
  void initState() {
    super.initState();
    listingsFuture = loadListings();
  }

  Future<List<Map<String, dynamic>>> loadListings() async {
    final response = await Supabase.instance.client
        .from('public_listings')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> refreshListings() async {
    final future = loadListings();
    setState(() {
      listingsFuture = future;
    });
    await future;
  }

  Future<void> openEditor([Map<String, dynamic>? item]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PropertyEditorDialog(item: item),
    );

    if (result == true && mounted) {
      await refreshListings();
    }
  }

  Future<void> deleteListing(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف فایل'),
        content: const Text('آیا از حذف این فایل ملکی اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('public_listings')
          .delete()
          .eq('id', id);

      await refreshListings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فایل حذف شد.')),
        );
      }
    } catch (e) {
      showError('خطا در حذف فایل: $e');
    }
  }

  Future<void> changePublication(String id, bool published) async {
    try {
      await Supabase.instance.client
          .from('public_listings')
          .update({'is_published': !published})
          .eq('id', id);

      await refreshListings();
    } catch (e) {
      showError('خطا در تغییر وضعیت انتشار: $e');
    }
  }

  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت املاک عسگری'),
          actions: [
            IconButton(
              tooltip: 'مدیریت مشتریان',
              icon: const Icon(Icons.people),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerManagementPage(),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'خروج',
              onPressed: logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: black,
          foregroundColor: gold,
          onPressed: () => openEditor(),
          icon: const Icon(Icons.add),
          label: const Text('ثبت فایل جدید'),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: listingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: gold),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('دریافت فایل‌ها با خطا مواجه شد.'),
                    TextButton(
                      onPressed: refreshListings,
                      child: const Text('تلاش مجدد'),
                    ),
                  ],
                ),
              );
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return const Center(
                child: Text('هنوز فایلی ثبت نشده است.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final id = item['id'].toString();
                final published = item['is_published'] == true;
                final images = item['image_urls'] is List
                    ? List<String>.from(item['image_urls'])
                    : <String>[];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (images.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (context, imageIndex) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    images[imageIndex],
                                    width: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          item['title']?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${item['category'] ?? ''} | '
                          '${item['property_type'] ?? ''}',
                        ),
                        Text(
                          'محله: ${item['neighborhood'] ?? 'ثبت نشده'}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              published
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: published ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(published ? 'منتشر شده' : 'پیش‌نویس'),
                            const Spacer(),
                            IconButton(
                              tooltip: 'انتشار',
                              onPressed: () =>
                                  changePublication(id, published),
                              icon: const Icon(
                                Icons.public,
                                color: Colors.green,
                              ),
                            ),
                            IconButton(
                              tooltip: 'ویرایش',
                              onPressed: () => openEditor(item),
                              icon: const Icon(Icons.edit, color: Colors.blue),
                            ),
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: () => deleteListing(id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// -------------------- HELPERS --------------------

String normalizeDigits(String value) {
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  const arabic = '٠١٢٣٤٥٦٧٨٩';

  for (int i = 0; i < 10; i++) {
    value = value.replaceAll(persian[i], '$i');
    value = value.replaceAll(arabic[i], '$i');
  }

  return value.replaceAll(',', '').replaceAll('٬', '');
}

num? parseNumber(String value) {
  final normalized = normalizeDigits(value.trim());
  if (normalized.isEmpty) return null;
  return num.tryParse(normalized);
}

int? parseInteger(String value) {
  final normalized = normalizeDigits(value.trim());
  if (normalized.isEmpty) return null;
  return int.tryParse(normalized);
}

// -------------------- PROPERTY EDITOR --------------------

class PropertyEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? item;

  const PropertyEditorDialog({super.key, this.item});

  @override
  State<PropertyEditorDialog> createState() =>
      _PropertyEditorDialogState();
}

class _PropertyEditorDialogState extends State<PropertyEditorDialog> {
  final formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  late final TextEditingController titleController;
  late final TextEditingController areaController;
  late final TextEditingController neighborhoodController;
  late final TextEditingController addressController;
  late final TextEditingController bedroomsController;
  late final TextEditingController floorController;
  late final TextEditingController salePriceController;
  late final TextEditingController depositController;
  late final TextEditingController rentController;
  late final TextEditingController displayPriceController;
  late final TextEditingController descriptionController;

  String category = 'فروش';
  String propertyType = 'آپارتمان';

  bool published = false;
  bool saving = false;
  bool pickingImages = false;

  List<String> existingImages = [];
  List<XFile> newImages = [];

  final propertyTypes = [
    'آپارتمان',
    'خانه',
    'زمین',
    'مغازه',
    'باغ',
    'سایر',
  ];

  @override
  void initState() {
    super.initState();

    final item = widget.item ?? {};

    titleController = TextEditingController(
      text: item['title']?.toString() ?? '',
    );
    areaController = TextEditingController(
      text: item['area']?.toString() ?? '',
    );
    neighborhoodController = TextEditingController(
      text: item['neighborhood']?.toString() ?? '',
    );
    addressController = TextEditingController(
      text: item['full_address']?.toString() ?? '',
    );
    bedroomsController = TextEditingController(
      text: item['bedrooms']?.toString() ?? '',
    );
    floorController = TextEditingController(
      text: item['floor_number']?.toString() ?? '',
    );
    salePriceController = TextEditingController(
      text: item['sale_price']?.toString() ?? '',
    );
    depositController = TextEditingController(
      text: item['deposit_amount']?.toString() ?? '',
    );
    rentController = TextEditingController(
      text: item['monthly_rent']?.toString() ?? '',
    );
    displayPriceController = TextEditingController(
      text: item['display_price']?.toString() ?? '',
    );
    descriptionController = TextEditingController(
      text: item['description']?.toString() ?? '',
    );

    if (item['image_urls'] is List) {
      existingImages = List<String>.from(item['image_urls']);
    }

    final savedCategory = item['category']?.toString();
    if (savedCategory == 'فروش' || savedCategory == 'رهن و اجاره') {
      category = savedCategory!;
    }

    final savedType = item['property_type']?.toString();
    if (savedType != null && propertyTypes.contains(savedType)) {
      propertyType = savedType;
    }

    published = item['is_published'] == true;
  }

  @override
  void dispose() {
    titleController.dispose();
    areaController.dispose();
    neighborhoodController.dispose();
    addressController.dispose();
    bedroomsController.dispose();
    floorController.dispose();
    salePriceController.dispose();
    depositController.dispose();
    rentController.dispose();
    displayPriceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImages() async {
    if (pickingImages || saving) return;

    setState(() {
      pickingImages = true;
    });

    try {
      final selected = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (!mounted) return;

      if (selected.isNotEmpty) {
        setState(() {
          newImages.addAll(selected);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('انتخاب تصاویر ناموفق بود: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          pickingImages = false;
        });
      }
    }
  }

  String contentTypeFor(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  Future<List<String>> uploadNewImages() async {
    final client = Supabase.instance.client;
    final uploadedUrls = <String>[];

    for (final image in newImages) {
      final extension = image.name.contains('.')
          ? image.name.split('.').last.toLowerCase()
          : 'jpg';

      final fileName =
          '${DateTime.now().microsecondsSinceEpoch}_${uploadedUrls.length}.$extension';

      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('نشست مدیر منقضی شده است. دوباره وارد شوید.');
      }

      final path = '${user.id}/$fileName';

      await client.storage.from('property-images').uploadBinary(
            path,
            await image.readAsBytes(),
            fileOptions: FileOptions(
              contentType: contentTypeFor(extension),
              upsert: false,
            ),
          );

      uploadedUrls.add(
        client.storage.from('property-images').getPublicUrl(path),
      );
    }

    return uploadedUrls;
  }

  Future<void> saveListing() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
    });

    try {
      final client = Supabase.instance.client;

      final uploadedUrls = await uploadNewImages();
      final allImages = [...existingImages, ...uploadedUrls];

      final data = <String, dynamic>{
        'title': titleController.text.trim(),
        'category': category,
        'property_type': propertyType,
        'area': parseNumber(areaController.text),
        'neighborhood': neighborhoodController.text.trim(),
        'full_address': addressController.text.trim(),
        'bedrooms': parseInteger(bedroomsController.text),
        'floor_number': parseInteger(floorController.text),
        'sale_price': parseNumber(salePriceController.text),
        'deposit_amount': parseNumber(depositController.text),
        'monthly_rent': parseNumber(rentController.text),
        'display_price': displayPriceController.text.trim(),
        'description': descriptionController.text.trim(),
        'is_published': published,
        'image_urls': allImages,
      };

      if (widget.item == null) {
        await client.from('public_listings').insert(data);
      } else {
        await client
            .from('public_listings')
            .update(data)
            .eq('id', widget.item!['id'].toString());
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره فایل یا تصاویر: $e')),
        );
        setState(() {
          saving = false;
        });
      }
    }
  }

  Widget textField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'این فیلد الزامی است.';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget imageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'تصاویر ملک',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: pickingImages || saving ? null : pickImages,
            icon: pickingImages
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate),
            label: Text(
              pickingImages ? 'در حال انتخاب...' : 'انتخاب تصاویر از گالری',
            ),
          ),
        ),
        if (existingImages.isNotEmpty || newImages.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 105,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...existingImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;

                  return imagePreview(
                    Image.network(
                      url,
                      width: 105,
                      height: 105,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                    () {
                      setState(() {
                        existingImages.removeAt(index);
                      });
                    },
                  );
                }),
                ...newImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;

                  return imagePreview(
                    Image.file(
                      File(file.path),
                      width: 105,
                      height: 105,
                      fit: BoxFit.cover,
                    ),
                    () {
                      setState(() {
                        newImages.removeAt(index);
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'تعداد تصاویر: ${existingImages.length + newImages.length}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  Widget imagePreview(Widget image, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 105,
              height: 105,
              child: image,
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: saving ? null : onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          widget.item == null ? 'ثبت فایل ملکی' : 'ویرایش فایل ملکی',
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  textField('عنوان فایل', titleController, required: true),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'نوع معامله'),
                    items: const [
                      DropdownMenuItem(
                        value: 'فروش',
                        child: Text('فروش'),
                      ),
                      DropdownMenuItem(
                        value: 'رهن و اجاره',
                        child: Text('رهن و اجاره'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          category = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: propertyType,
                    decoration: const InputDecoration(labelText: 'نوع ملک'),
                    items: propertyTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          propertyType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  textField(
                    'متراژ',
                    areaController,
                    keyboardType: TextInputType.number,
                  ),
                  textField('محله', neighborhoodController),
                  textField('آدرس کامل', addressController),
                  textField(
                    'تعداد اتاق خواب',
                    bedroomsController,
                    keyboardType: TextInputType.number,
                  ),
                  textField(
                    'طبقه',
                    floorController,
                    keyboardType: TextInputType.number,
                  ),
                  textField(
                    'قیمت فروش (تومان)',
                    salePriceController,
                    keyboardType: TextInputType.number,
                  ),
                  textField(
                    'مبلغ رهن (تومان)',
                    depositController,
                    keyboardType: TextInputType.number,
                  ),
                  textField(
                    'اجاره ماهانه (تومان)',
                    rentController,
                    keyboardType: TextInputType.number,
                  ),
                  textField('متن قیمت نمایشی', displayPriceController),
                  textField(
                    'توضیحات ملک',
                    descriptionController,
                    maxLines: 4,
                  ),
                  imageSection(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('انتشار آگهی برای عموم'),
                    value: published,
                    activeThumbColor: gold,
                    onChanged: saving
                        ? null
                        : (value) {
                            setState(() {
                              published = value;
                            });
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving
                ? null
                : () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: black,
              foregroundColor: gold,
            ),
            onPressed: saving ? null : saveListing,
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: gold,
                    ),
                  )
                : const Text('ذخیره فایل'),
          ),
        ],
      ),
    );
  }
}

// -------------------- CUSTOMER MANAGEMENT --------------------

class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({super.key});

  @override
  State<CustomerManagementPage> createState() =>
      _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  late Future<List<Map<String, dynamic>>> customersFuture;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    customersFuture = loadCustomers();
  }

  Future<List<Map<String, dynamic>>> loadCustomers() async {
    final response = await Supabase.instance.client
        .from('customers')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> refreshCustomers() async {
    final future = loadCustomers();
    setState(() {
      customersFuture = future;
    });
    await future;
  }

  Future<void> openCustomerEditor(
      [Map<String, dynamic>? customer]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomerEditorDialog(customer: customer),
    );

    if (result == true && mounted) {
      await refreshCustomers();
    }
  }

  Future<void> deleteCustomer(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف مشتری'),
        content: const Text(
          'آیا از حذف اطلاعات این مشتری مطمئن هستید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('customers')
          .delete()
          .eq('id', id);

      await refreshCustomers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مشتری حذف شد.')),
        );
      }
    } catch (e) {
      showMessage('خطا در حذف مشتری: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت مشتریان'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: black,
          foregroundColor: gold,
          onPressed: () => openCustomerEditor(),
          icon: const Icon(Icons.person_add),
          label: const Text('ثبت مشتری'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'جستجو با نام یا شماره تماس...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = normalizeDigits(value.trim());
                  });
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: customersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: gold),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('دریافت مشتریان با خطا مواجه شد.'),
                          TextButton(
                            onPressed: refreshCustomers,
                            child: const Text('تلاش مجدد'),
                          ),
                        ],
                      ),
                    );
                  }

                  final customers = snapshot.data ?? [];

                  final filtered = customers.where((customer) {
                    final name =
                        (customer['full_name'] ?? '').toString();
                    final phone = normalizeDigits(
                      (customer['phone'] ?? '').toString(),
                    );

                    return searchText.isEmpty ||
                        name.contains(searchText) ||
                        phone.contains(searchText);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('مشتری‌ای ثبت نشده است.'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: refreshCustomers,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          12, 4, 12, 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final customer = filtered[index];
                        final id = customer['id'].toString();

                        final name =
                            customer['full_name']?.toString() ?? '';
                        final phone =
                            customer['phone']?.toString() ?? '';
                        final demand =
                            customer['demand']?.toString() ?? '';
                        final budget =
                            customer['budget']?.toString() ?? '';
                        final status =
                            customer['status']?.toString() ?? 'جدید';
                        final propertyType =
                            customer['property_type']?.toString() ?? '';
                        final neighborhood =
                            customer['neighborhood']?.toString() ?? '';
                        final followUp =
                            customer['follow_up_date']?.toString() ?? '';

                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('شماره تماس: $phone'),
                                if (demand.isNotEmpty)
                                  Text('نوع درخواست: $demand'),
                                if (propertyType.isNotEmpty)
                                  Text('نوع ملک: $propertyType'),
                                if (budget.isNotEmpty && budget != 'null')
                                  Text('بودجه: $budget تومان'),
                                if (neighborhood.isNotEmpty)
                                  Text('محله موردنظر: $neighborhood'),
                                if (followUp.isNotEmpty &&
                                    followUp != 'null')
                                  Text('تاریخ پیگیری: $followUp'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('وضعیت: '),
                                    Expanded(
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'تماس',
                                      onPressed: () async {
                                        final uri = Uri(
                                          scheme: 'tel',
                                          path: phone,
                                        );
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.phone,
                                        color: Colors.green,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'ویرایش',
                                      onPressed: () =>
                                          openCustomerEditor(customer),
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'حذف',
                                      onPressed: () => deleteCustomer(id),
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- CUSTOMER EDITOR --------------------

class CustomerEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? customer;

  const CustomerEditorDialog({super.key, this.customer});

  @override
  State<CustomerEditorDialog> createState() =>
      _CustomerEditorDialogState();
}

class _CustomerEditorDialogState extends State<CustomerEditorDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController demandController;
  late final TextEditingController budgetController;
  late final TextEditingController propertyTypeController;
  late final TextEditingController neighborhoodController;
  late final TextEditingController notesController;

  String status = 'جدید';
  DateTime? followUpDate;
  bool saving = false;

  final statuses = [
    'جدید',
    'در حال پیگیری',
    'مشتری جدی',
    'معامله انجام شد',
    'بایگانی',
  ];

  @override
  void initState() {
    super.initState();

    final item = widget.customer ?? {};

    nameController = TextEditingController(
      text: item['full_name']?.toString() ?? '',
    );
    phoneController = TextEditingController(
      text: item['phone']?.toString() ?? '',
    );
    demandController = TextEditingController(
      text: item['demand']?.toString() ?? '',
    );
    budgetController = TextEditingController(
      text: item['budget']?.toString() ?? '',
    );
    propertyTypeController = TextEditingController(
      text: item['property_type']?.toString() ?? '',
    );
    neighborhoodController = TextEditingController(
      text: item['neighborhood']?.toString() ?? '',
    );
    notesController = TextEditingController(
      text: item['notes']?.toString() ?? '',
    );

    final savedStatus = item['status']?.toString();
    if (savedStatus != null && statuses.contains(savedStatus)) {
      status = savedStatus;
    }

    final savedDate = item['follow_up_date']?.toString();
    if (savedDate != null &&
        savedDate.isNotEmpty &&
        savedDate != 'null') {
      followUpDate = DateTime.tryParse(savedDate);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    demandController.dispose();
    budgetController.dispose();
    propertyTypeController.dispose();
    neighborhoodController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> chooseFollowUpDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: followUpDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'انتخاب تاریخ پیگیری',
    );

    if (selected != null && mounted) {
      setState(() {
        followUpDate = selected;
      });
    }
  }

  String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> saveCustomer() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
    });

    try {
      final data = <String, dynamic>{
        'full_name': nameController.text.trim(),
        'phone': normalizeDigits(phoneController.text.trim()),
        'demand': demandController.text.trim(),
        'budget': parseNumber(budgetController.text),
        'property_type': propertyTypeController.text.trim(),
        'neighborhood': neighborhoodController.text.trim(),
        'notes': notesController.text.trim(),
        'status': status,
        'follow_up_date': followUpDate == null
            ? null
            : formatDate(followUpDate!),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final client = Supabase.instance.client;

      if (widget.customer == null) {
        await client.from('customers').insert(data);
      } else {
        await client
            .from('customers')
            .update(data)
            .eq('id', widget.customer!['id'].toString());
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره مشتری: $e')),
        );
        setState(() {
          saving = false;
        });
      }
    }
  }

  Widget field(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'این فیلد الزامی است.';
                }
                return null;
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(
          widget.customer == null
              ? 'ثبت مشتری جدید'
              : 'ویرایش اطلاعات مشتری',
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  field(
                    'نام و نام خانوادگی',
                    nameController,
                    required: true,
                  ),
                  field(
                    'شماره تماس',
                    phoneController,
                    keyboardType: TextInputType.phone,
                    required: true,
                  ),
                  field(
                    'نوع درخواست (خرید، فروش، رهن یا اجاره)',
                    demandController,
                    required: true,
                  ),
                  field(
                    'بودجه به تومان',
                    budgetController,
                    keyboardType: TextInputType.number,
                  ),
                  field('نوع ملک موردنظر', propertyTypeController),
                  field('محله موردنظر', neighborhoodController),
                  field(
                    'توضیحات و جزئیات مشتری',
                    notesController,
                    maxLines: 3,
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'وضعیت مشتری',
                    ),
                    items: statuses.map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                status = value;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : chooseFollowUpDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        followUpDate == null
                            ? 'تعیین تاریخ پیگیری'
                            : 'پیگیری: ${formatDate(followUpDate!)}',
                      ),
                    ),
                  ),
                  if (followUpDate != null)
                    TextButton(
                      onPressed: saving
                          ? null
                          : () {
                              setState(() {
                                followUpDate = null;
                              });
                            },
                      child: const Text('پاک کردن تاریخ پیگیری'),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving
                ? null
                : () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: black,
              foregroundColor: gold,
            ),
            onPressed: saving ? null : saveCustomer,
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: gold,
                    ),
                  )
                : const Text('ذخیره مشتری'),
          ),
        ],
      ),
    );
  }
}
