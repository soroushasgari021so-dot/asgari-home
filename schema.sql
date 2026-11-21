-- ASGARI HOME: minimum database schema for the current starter app.
-- Run this file in Supabase SQL Editor.

create table if not exists public.public_listings (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null check (category in ('فروش', 'رهن و اجاره')),
  area numeric(10,2),
  neighborhood text,
  display_price text,
  description text,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists public_listings_created_at_idx
  on public.public_listings (created_at desc);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.public_listings enable row level security;
alter table public.admin_users enable row level security;

-- Anyone can read only published property ads.
drop policy if exists "Public can read published listings" on public.public_listings;
create policy "Public can read published listings"
  on public.public_listings for select
  to anon, authenticated
  using (is_published = true);

-- A signed-in administrator can read only their own membership row.
drop policy if exists "Admins can read own membership" on public.admin_users;
create policy "Admins can read own membership"
  on public.admin_users for select
  to authenticated
  using (auth.uid() = user_id);

-- Do not enable client-side inserts/updates/deletes yet. The current app
-- only reads public listings and verifies admin membership.
