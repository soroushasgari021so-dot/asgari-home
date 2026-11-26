
from pathlib import Path
import sys

MAIN = Path("lib/main.dart")
source = MAIN.read_text(encoding="utf-8")

def once(old, new, label):
    global source
    count = source.count(old)
    if count != 1:
        raise SystemExit(f"Patch stopped: expected one match for {label}, found {count}. No file was written.")
    source = source.replace(old, new, 1)

once("title: 'ASGARI HOME',", "title: 'asgarihome',", "app title")

once(
'''                final title = (item['title'] ?? '').toString();
                final neighborhood =
                    (item['neighborhood'] ?? '').toString();
                final category = (item['category'] ?? '').toString();

                final matchesSearch = searchText.isEmpty ||
                    title.contains(searchText) ||
                    neighborhood.contains(searchText);''',
'''                final title = (item['title'] ?? '').toString();
                final neighborhood =
                    (item['neighborhood'] ?? '').toString();
                final fileCode = normalizeDigits(
                    (item['file_code'] ?? '').toString()).toUpperCase();
                final category = (item['category'] ?? '').toString();

                final matchesSearch = searchText.isEmpty ||
                    title.contains(searchText) ||
                    neighborhood.contains(searchText) ||
                    fileCode.contains(searchText);''',
"public search"
)
once("searchText = value.trim();",
     "searchText = normalizeDigits(value.trim()).toUpperCase();",
     "normalized search input")

start = source.index("class ListingCard extends StatelessWidget {")
end = source.index("// -------------------- LISTING DETAILS --------------------", start)
compact_card = r'''class ListingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const ListingCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? 'ملک بدون عنوان';
    final category = item['category']?.toString() ?? '';
    final type = item['property_type']?.toString() ?? '';
    final area = item['area']?.toString() ?? '';
    final neighborhood = item['neighborhood']?.toString() ?? '';
    final fileCode = item['file_code']?.toString() ?? '';
    final price = formatPriceText(item['display_price']?.toString() ?? '');
    final images = item['image_urls'] is List
        ? List<String>.from(item['image_urls'])
        : <String>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: const BorderSide(color: gold, width: 0.45),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final listingId = item['id']?.toString();
          if (listingId != null && listingId.isNotEmpty) {
            unawaited(
              Supabase.instance.client
                  .rpc('increment_listing_view',
                      params: {'p_listing_id': listingId})
                  .then<void>((_) {}, onError: (_) {}),
            );
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailsPage(item: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: images.isNotEmpty
                    ? Image.network(
                        images.first,
                        width: 94,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 8, runSpacing: 2, children: [
                      if (category.isNotEmpty)
                        Text(category, style: const TextStyle(fontSize: 11, color: gold, fontWeight: FontWeight.bold)),
                      if (fileCode.isNotEmpty)
                        Text('کد: $fileCode', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ]),
                    const SizedBox(height: 3),
                    Text([
                      if (type.isNotEmpty) type,
                      if (area.isNotEmpty) '$area متر',
                      if (neighborhood.isNotEmpty) neighborhood,
                    ].join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    if (price.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(price, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 3),
                    const Text('املاک عسگری نهاوند  |  مشاهده جزئیات ←',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    width: 94, height: 88, color: Colors.grey.shade200,
    child: const Icon(Icons.home_work, size: 35, color: Colors.grey),
  );
}

'''
source = source[:start] + compact_card + source[end:]

once(
'''    final title = item['title']?.toString() ?? 'ملک بدون عنوان';
    final category = item['category']?.toString() ?? '';
    final propertyType = item['property_type']?.toString() ?? '';''',
'''    final title = item['title']?.toString() ?? 'ملک بدون عنوان';
    final fileCode = item['file_code']?.toString() ?? '';
    final category = item['category']?.toString() ?? '';
    final propertyType = item['property_type']?.toString() ?? '';''',
"details code variable"
)
once(
'''                  detailRow(Icons.swap_horiz, 'نوع معامله', category),
                  detailRow(Icons.home_work, 'نوع ملک', propertyType),''',
'''                  detailRow(Icons.qr_code, 'کد فایل', fileCode),
                  detailRow(Icons.swap_horiz, 'نوع معامله', category),
                  detailRow(Icons.home_work, 'نوع ملک', propertyType),''',
"details code row"
)
once(
'''                        Text(
                          item['title']?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),''',
'''                        Text(
                          item['title']?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if ((item['file_code'] ?? '').toString().isNotEmpty)
                          Text('کد فایل: ${item['file_code']}',
                              style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),''',
"admin code label"
)
once(
'''  late final TextEditingController titleController;
  late final TextEditingController areaController;''',
'''  late final TextEditingController titleController;
  late final TextEditingController fileCodeController;
  late final TextEditingController areaController;''',
"file code controller declaration"
)
once(
'''    titleController = TextEditingController(
      text: item['title']?.toString() ?? '',
    );
    areaController = TextEditingController(''',
'''    titleController = TextEditingController(
      text: item['title']?.toString() ?? '',
    );
    fileCodeController = TextEditingController(
      text: item['file_code']?.toString() ?? '',
    );
    areaController = TextEditingController(''',
"file code controller init"
)
once(
'''    titleController.dispose();
    areaController.dispose();''',
'''    titleController.dispose();
    fileCodeController.dispose();
    areaController.dispose();''',
"file code controller dispose"
)
once(
'''                  textField('عنوان فایل', titleController, required: true),
                  DropdownButtonFormField<String>(''',
'''                  textField('عنوان فایل', titleController, required: true),
                  textField('کد فایل (الزامی؛ مانند ۱۰۲۵ یا AS-1025)',
                      fileCodeController, required: true),
                  DropdownButtonFormField<String>(''',
"file code input"
)
once(
'''      final client = Supabase.instance.client;

      final uploadedUrls = await uploadNewImages();''',
'''      final client = Supabase.instance.client;
      final fileCode = normalizeDigits(fileCodeController.text.trim()).toUpperCase();
      if (fileCode.isEmpty || !RegExp(r'^[A-Z0-9-]+$').hasMatch(fileCode)) {
        throw Exception('کد فایل الزامی است و فقط باید شامل حروف انگلیسی، عدد یا خط تیره باشد.');
      }

      final matchingCodes = await client
          .from('public_listings')
          .select('id')
          .ilike('file_code', fileCode);
      final currentId = widget.item?['id']?.toString();
      final duplicate = matchingCodes.any(
        (row) => row['id']?.toString() != currentId,
      );
      if (duplicate) {
        throw Exception('این کد فایل قبلاً برای ملک دیگری ثبت شده است.');
      }

      final uploadedUrls = await uploadNewImages();''',
"unique code validation"
)
once(
'''      final data = <String, dynamic>{
        'title': titleController.text.trim(),
        'category': category,''',
'''      final data = <String, dynamic>{
        'title': titleController.text.trim(),
        'file_code': fileCode,
        'category': category,''',
"persist file code"
)

MAIN.write_text(source, encoding="utf-8")
print("Patched lib/main.dart.")
