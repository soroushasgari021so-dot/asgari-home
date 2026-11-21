import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const telegramUsername = 'amlak_asgari';
const officePhone = String.fromEnvironment(
  'OFFICE_PHONE',
  defaultValue: '09363882379',
);

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isSupabaseConfigured) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const AsgariApp());
}

class AsgariApp extends StatelessWidget {
  const AsgariApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'املاک عسگری',
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xff101010),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xffc6a04b),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xff171717),
            foregroundColor: Color(0xffe0bd69),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xff1b1b1b),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('املاک عسگری',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('نهاوند | ASGARI HOME',
                    style: TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'ارتباط با دفتر',
                onPressed: () => _contact(context),
                icon: const Icon(Icons.support_agent),
              ),
            ],
          ),
          body: IndexedStack(
            index: tab,
            children: const [PublicListings(), AdminGate()],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined), label: 'آگهی‌ها'),
              NavigationDestination(
                  icon: Icon(Icons.lock_outline), label: 'مدیریت مدیران'),
            ],
          ),
        ),
      );

  Future<void> _contact(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Wrap(
            children: [
              const ListTile(
                title: Text('ارتباط با املاک عسگری',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.telegram),
                title: const Text('گفت‌وگو در تلگرام'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await launchUrl(
                    Uri.parse('https://t.me/$telegramUsername'),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('تماس تلفنی'),
                subtitle: Text(officePhone),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await launchUrl(Uri(scheme: 'tel', path: officePhone));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetupNotice extends StatelessWidget {
  const SetupNotice({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.cloud_off,
                      color: Color(0xffc6a04b), size: 42),
                  SizedBox(height: 12),
                  Text('اتصال پایگاه داده هنوز تنظیم نشده',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  SizedBox(height: 8),
                  Text(
                    'برای فعال‌شدن آگهی‌های آنلاین و ورود مدیران، اطلاعات اتصال Supabase باید در تنظیمات مخزن GitHub ثبت و برنامه دوباره ساخته شود.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class PublicListings extends StatefulWidget {
  const PublicListings({super.key});
  @override
  State<PublicListings> createState() => _PublicListingsState();
}

class _PublicListingsState extends State<PublicListings> {
  String category = 'همه';
  String search = '';
  late Future<List<Map<String, dynamic>>> listingsFuture;

  @override
  void initState() {
    super.initState();
    listingsFuture = _loadListings();
  }

  Future<List<Map<String, dynamic>>> _loadListings() async {
    if (!isSupabaseConfigured) return [];
    final rows = await Supabase.instance.client
        .from('public_listings')
        .select()
        .eq('is_published', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  void _refresh() {
    setState(() => listingsFuture = _loadListings());
  }

  @override
  Widget build(BuildContext context) {
    if (!isSupabaseConfigured) return const SetupNotice();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'جست‌وجو در آگهی‌ها',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => search = value.trim()),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: ['همه', 'فروش', 'رهن و اجاره']
                .map((value) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(value),
                        selected: category == value,
                        onSelected: (_) => setState(() => category = value),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: listingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('دریافت آگهی‌ها ممکن نشد.'),
                      TextButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('تلاش دوباره'),
                      ),
                    ],
                  ),
                );
              }
              final rows = (snapshot.data ?? []).where((item) {
                final matchesCategory =
                    category == 'همه' || item['category'] == category;
                final text =
                    '${item['title'] ?? ''} ${item['neighborhood'] ?? ''}';
                return matchesCategory && text.contains(search);
              }).toList();
              if (rows.isEmpty) {
                return const Center(
                    child: Text('در حال حاضر آگهی منتشرشده‌ای وجود ندارد.'));
              }
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  itemBuilder: (context, index) =>
                      ListingCard(item: rows[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ListingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const ListingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${item['title'] ?? 'ملک'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Text('${item['category'] ?? ''}',
                      style: const TextStyle(color: Color(0xffd6b45e))),
                ],
              ),
              const SizedBox(height: 8),
              Text('${item['area'] ?? '—'} متر | ${item['neighborhood'] ?? 'نهاوند'}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('${item['display_price'] ?? 'تماس بگیرید'}',
                  style: const TextStyle(
                      color: Color(0xffd6b45e), fontWeight: FontWeight.bold)),
              if (item['description'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${item['description']}'),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://t.me/$telegramUsername'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('استعلام از املاک عسگری'),
                ),
              ),
            ],
          ),
        ),
      );
}

class AdminGate extends StatefulWidget {
  const AdminGate({super.key});
  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (!isSupabaseConfigured) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final client = Supabase.instance.client;
      final result = await client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final user = result.user;
      if (user == null) throw Exception('ورود ناموفق بود.');
      final membership = await client
          .from('admin_users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (membership == null) {
        await client.auth.signOut();
        throw Exception('این حساب دسترسی مدیریت ندارد.');
      }
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!isSupabaseConfigured) return const SetupNotice();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      return AdminDashboard(
        email: user.email ?? '',
        onSignOut: () { if (mounted) setState(() {}); },
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: Color(0xffd6b45e), size: 42),
                const SizedBox(height: 10),
                const Text('ورود مدیران',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'ایمیل مدیر'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'رمز عبور'),
                  onSubmitted: (_) => signIn(),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : signIn,
                    child: Text(busy ? 'در حال بررسی...' : 'ورود امن'),
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

class AdminDashboard extends StatelessWidget {
  final String email;
  final VoidCallback onSignOut;
  const AdminDashboard({super.key, required this.email, required this.onSignOut});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user,
                      color: Color(0xffd6b45e), size: 40),
                  const Text('پنل مدیریت خصوصی',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(email, style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 12),
                  const Text(
                    'ورود مدیر تأیید شد. امکانات ثبت و مدیریت ملک در مراحل بعدی توسعه اضافه می‌شوند.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      onSignOut();
                    },
                    child: const Text('خروج از حساب'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
