# ASGARI HOME | املاک عسگری

اپلیکیشن اندرویدی فارسی مجموعه املاک عسگری در نهاوند با رابط مشکی و طلایی.

## وضعیت این نسخه
این بسته یک نسخه پایه و قابل توسعه است؛ هنوز سامانه کامل مدیریت دفتر املاک نیست.

### قابلیت‌های پیاده‌سازی‌شده
- رابط فارسی راست‌چین و جابه‌جایی بین آگهی‌ها و ورود مدیران
- نمایش آگهی‌های منتشرشده از Supabase و جست‌وجو/دسته‌بندی آن‌ها
- ورود ایمیل و رمز مدیر از Supabase Auth و بررسی عضویت در `admin_users`
- لینک تماس تلگرامی `@amlak_asgari` و تماس تلفنی
- ساخت APK با GitHub Actions
- نمایش صفحه راهنما به‌جای توقف برنامه، اگر تنظیمات Supabase هنوز ثبت نشده باشند

### مواردی که هنوز ساخته نشده‌اند
ثبت، ویرایش و حذف آگهی از داخل برنامه؛ پرونده مالک و متقاضی؛ پیگیری تماس و بازدید؛ قراردادها؛ محاسبه کمیسیون و گزارش مالی. این موارد نباید تا زمان پیاده‌سازی، آماده یا فعال فرض شوند.

## ساختار مخزن
محتویات ZIP باید مستقیماً در ریشه مخزن GitHub قرار گیرند؛ پوشه والد ZIP را به‌عنوان یک پوشه اضافی در مخزن بارگذاری نکنید.

```text
.
├── .github/workflows/build-apk.yml
├── lib/main.dart
├── supabase/schema.sql
├── pubspec.yaml
├── README.md
└── .gitignore
```

## تنظیم GitHub Secrets
در مخزن GitHub از مسیر `Settings` → `Secrets and variables` → `Actions` دو Secret زیر را ایجاد کنید:

- `SUPABASE_URL`: آدرس پروژه Supabase
- `SUPABASE_ANON_KEY`: کلید عمومی Publishable/Anon پروژه

کلید `service_role` یا هر کلید محرمانه را در برنامه، فایل‌ها یا مخزن عمومی قرار ندهید.

## راه‌اندازی Supabase
1. در پروژه Supabase وارد SQL Editor شوید.
2. محتوای `supabase/schema.sql` را اجرا کنید.
3. در Authentication یک کاربر مدیر بسازید.
4. UUID کاربر را از فهرست Users بردارید و در دستور زیر جایگزین کنید:

```sql
insert into public.admin_users (user_id)
values ('UUID-OF-ADMIN-USER')
on conflict (user_id) do nothing;
```

برای ثبت یک آگهی آزمایشی:

```sql
insert into public.public_listings
(title, category, area, neighborhood, display_price, description, is_published)
values
('آپارتمان نمونه', 'فروش', 85, 'مرکز شهر', 'تماس بگیرید', 'آگهی آزمایشی املاک عسگری', true);
```

## ساخت APK
با هر Push به شاخه `main`، یا با اجرای دستی Workflow با نام `Build ASGARI HOME APK`، فایل APK ساخته می‌شود. پس از موفقیت، از بخش Artifacts فایل `asgari-home-apk` را دانلود کنید.

## امنیت
- سیاست‌های RLS در SQL فقط خواندن آگهی‌های منتشرشده و خواندن ردیف عضویت خود مدیر را مجاز می‌کنند.
- این نسخه عمداً مجوز نوشتن/حذف آگهی را از کلاینت فعال نمی‌کند.
- امنیت داده‌ها باید با RLS حفظ شود؛ کلید عمومی به‌تنهایی جایگزین سیاست‌های دسترسی نیست.
