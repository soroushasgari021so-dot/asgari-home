-- طرح اولیه پایگاه داده؛ پیش از استفاده واقعی باید RLS و سیاست‌های دسترسی
-- مطابق دو مدیر مجاز و آگهی‌های عمومی بازبینی و فعال شوند.
create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  property_type text not null,
  deal_type text not null check (deal_type in ('sale','rent','mortgage','mortgage_rent')),
  city text not null default 'نهاوند',
  area_m2 numeric,
  bedrooms integer,
  price numeric,
  mortgage numeric,
  monthly_rent numeric,
  description text,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.property_images (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  image_path text not null,
  sort_order integer not null default 0
);

alter table public.properties enable row level security;
alter table public.property_images enable row level security;

-- هیچ policy عمومی برای داده‌های خصوصی تعریف نشده است.
-- سیاست‌های امن مدیران و خواندن آگهی‌های منتشرشده باید پس از ساخت Auth
-- و ثبت شناسه دو مدیر به‌صورت دقیق اضافه شوند.
