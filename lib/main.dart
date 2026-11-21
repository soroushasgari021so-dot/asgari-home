
class AdminDashboard extends StatefulWidget {
  final String email;
  final VoidCallback onSignOut;

  const AdminDashboard({
    super.key,
    required this.email,
    required this.onSignOut,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<List<Map<String, dynamic>>> listingsFuture;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    listingsFuture = _loadListings();
  }

  Future<List<Map<String, dynamic>>> _loadListings() async {
    final rows = await Supabase.instance.client
        .from('public_listings')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  void _refresh() {
    setState(() {
      listingsFuture = _loadListings();
    });
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openEditor({
    Map<String, dynamic>? item,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => PropertyEditorDialog(item: item),
    );

    if (result == null || !mounted) return;

    setState(() => busy = true);

    try {
      final client = Supabase.instance.client;

      if (item == null) {
        await client.from('public_listings').insert(result);
        _message('ملک با موفقیت ثبت شد.');
      } else {
        await client
            .from('public_listings')
            .update(result)
            .eq('id', item['id']);
        _message('اطلاعات ملک ویرایش شد.');
      }

      _refresh();
    } catch (e) {
      _message('ثبت اطلاعات ناموفق بود: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف فایل ملک'),
        content: Text(
          'آیا از حذف «${item['title']}» اطمینان داری؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف شود'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('public_listings')
          .delete()
          .eq('id', item['id']);

      _message('ملک حذف شد.');
      _refresh();
    } catch (e) {
      _message('حذف ملک ناموفق بود: $e');
    }
  }

  Future<void> _changePublication(
    Map<String, dynamic> item,
    bool value,
  ) async {
    try {
      await Supabase.instance.client
          .from('public_listings')
          .update({'is_published': value})
          .eq('id', item['id']);

      _message(
        value ? 'آگهی منتشر شد.' : 'آگهی از نمایش عمومی خارج شد.',
      );
      _refresh();
    } catch (e) {
      _message('تغییر وضعیت انتشار ناموفق بود: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: Color(0xffd6b45e),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'پنل مدیریت املاک',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          widget.email,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'خروج از حساب',
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      widget.onSignOut();
                    },
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : () => _openEditor(),
                  icon: const Icon(Icons.add_home),
                  label: const Text('ثبت ملک جدید'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'تازه‌سازی',
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'فهرست فایل‌های ملکی',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: listingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('دریافت فایل‌ها ناموفق بود.'),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('تلاش دوباره'),
                      ),
                    ],
                  ),
                );
              }

              final rows = snapshot.data ?? [];

              if (rows.isEmpty) {
                return const Center(
                  child: Text('هنوز ملکی ثبت نشده است.'),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final item = rows[index];
                    final published = item['is_published'] == true;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['title'] ?? 'بدون عنوان'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${item['category'] ?? ''} | '
                              '${item['area'] ?? '—'} متر | '
                              '${item['neighborhood'] ?? 'بدون محله'}',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${item['display_price'] ?? 'قیمت ثبت نشده'}',
                              style: const TextStyle(
                                color: Color(0xffd6b45e),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('انتشار آگهی عمومی'),
                              subtitle: Text(
                                published ? 'منتشرشده' : 'منتشرنشده',
                              ),
                              value: published,
                              onChanged: (value) =>
                                  _changePublication(item, value),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _openEditor(item: item),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('ویرایش'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _delete(item),
                                  color: Colors.redAccent,
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'حذف ملک',
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
        if (busy) const LinearProgressIndicator(),
      ],
    );
  }
}

class PropertyEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? item;

  const PropertyEditorDialog({
    super.key,
    this.item,
  });

  @override
  State<PropertyEditorDialog> createState() =>
      _PropertyEditorDialogState();
}

class _PropertyEditorDialogState extends State<PropertyEditorDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController title;
  late final TextEditingController area;
  late final TextEditingController neighborhood;
  late final TextEditingController address;
  late final TextEditingController bedrooms;
  late final TextEditingController floor;
  late final TextEditingController salePrice;
  late final TextEditingController deposit;
  late final TextEditingController rent;
  late final TextEditingController displayPrice;
  late final TextEditingController description;

  String category = 'فروش';
  String propertyType = 'آپارتمان';
  bool published = false;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    title = TextEditingController(text: '${item?['title'] ?? ''}');
    area = TextEditingController(text: '${item?['area'] ?? ''}');
    neighborhood = TextEditingController(
      text: '${item?['neighborhood'] ?? ''}',
    );
    address = TextEditingController(
      text: '${item?['full_address'] ?? ''}',
    );
    bedrooms = TextEditingController(
      text: '${item?['bedrooms'] ?? ''}',
    );
    floor = TextEditingController(
      text: '${item?['floor_number'] ?? ''}',
    );
    salePrice = TextEditingController(
      text: '${item?['sale_price'] ?? ''}',
    );
    deposit = TextEditingController(
      text: '${item?['deposit_amount'] ?? ''}',
    );
    rent = TextEditingController(
      text: '${item?['monthly_rent'] ?? ''}',
    );
    displayPrice = TextEditingController(
      text: '${item?['display_price'] ?? ''}',
    );
    description = TextEditingController(
      text: '${item?['description'] ?? ''}',
    );

    category = item?['category'] ?? 'فروش';
    propertyType = item?['property_type'] ?? 'آپارتمان';
    published = item?['is_published'] == true;
  }

  @override
  void dispose() {
    title.dispose();
    area.dispose();
    neighborhood.dispose();
    address.dispose();
    bedrooms.dispose();
    floor.dispose();
    salePrice.dispose();
    deposit.dispose();
    rent.dispose();
    displayPrice.dispose();
    description.dispose();
    super.dispose();
  }

  num? _number(String value) {
    if (value.trim().isEmpty) return null;
    return num.tryParse(value.trim());
  }

  int? _integer(String value) {
    if (value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(context, <String, dynamic>{
      'title': title.text.trim(),
      'category': category,
      'property_type': propertyType,
      'area': _number(area.text),
      'neighborhood': neighborhood.text.trim(),
      'full_address': address.text.trim(),
      'bedrooms': _integer(bedrooms.text),
      'floor_number': _integer(floor.text),
      'sale_price': _number(salePrice.text),
      'deposit_amount': _number(deposit.text),
      'monthly_rent': _number(rent.text),
      'display_price': displayPrice.text.trim(),
      'description': description.text.trim(),
      'is_published': published,
    });
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? 'این قسمت الزامی است.'
                : null
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
          widget.item == null ? 'ثبت ملک جدید' : 'ویرایش ملک',
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field('عنوان ملک', title, required: true),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'نوع معامله',
                      border: OutlineInputBorder(),
                    ),
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
                        setState(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: propertyType,
                    decoration: const InputDecoration(
                      labelText: 'نوع ملک',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'آپارتمان',
                        child: Text('آپارتمان'),
                      ),
                      DropdownMenuItem(
                        value: 'خانه',
                        child: Text('خانه'),
                      ),
                      DropdownMenuItem(
                        value: 'زمین',
                        child: Text('زمین'),
                      ),
                      DropdownMenuItem(
                        value: 'مغازه',
                        child: Text('مغازه'),
                      ),
                      DropdownMenuItem(
                        value: 'باغ',
                        child: Text('باغ'),
                      ),
                      DropdownMenuItem(
                        value: 'سایر',
                        child: Text('سایر'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => propertyType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    'متراژ (متر)',
                    area,
                    keyboard: TextInputType.number,
                  ),
                  _field('محله', neighborhood),
                  _field('آدرس کامل', address),
                  _field(
                    'تعداد اتاق خواب',
                    bedrooms,
                    keyboard: TextInputType.number,
                  ),
                  _field(
                    'طبقه',
                    floor,
                    keyboard: TextInputType.number,
                  ),
                  const Divider(),
                  _field(
                    'قیمت فروش (تومان)',
                    salePrice,
                    keyboard: TextInputType.number,
                  ),
                  _field(
                    'مبلغ رهن (تومان)',
                    deposit,
                    keyboard: TextInputType.number,
                  ),
                  _field(
                    'اجاره ماهانه (تومان)',
                    rent,
                    keyboard: TextInputType.number,
                  ),
                  _field('متن قیمت نمایشی', displayPrice),
                  _field('توضیحات ملک', description),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('انتشار آگهی'),
                    value: published,
                    onChanged: (value) {
                      setState(() => published = value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: _save,
            child: const Text('ذخیره ملک'),
          ),
        ],
      ),
    );
  }
}
