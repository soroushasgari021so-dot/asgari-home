-- Consolidate overlapping permissive RLS policies without changing intended access.
-- Reviewed against live policy definitions on 2026-11-27.
-- Admin membership remains defined by private.is_admin().

-- admin_users: preserve self-read for non-admin authenticated users and full
-- management for admins, while using a single SELECT policy.
drop policy if exists "Admins can manage admin users" on public.admin_users;
drop policy if exists "admin_users_read_own" on public.admin_users;

create policy "admin_users_select_self_or_admin"
on public.admin_users
for select
to authenticated
using ((select auth.uid()) = user_id or (select private.is_admin()));

create policy "admin_users_insert_admin"
on public.admin_users
for insert
to authenticated
with check ((select private.is_admin()));

create policy "admin_users_update_admin"
on public.admin_users
for update
to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

create policy "admin_users_delete_admin"
on public.admin_users
for delete
to authenticated
using ((select private.is_admin()));


-- customers: both ALL policies are permissive and grant the same admin access.
-- Keep the policy that delegates to the hardened private.is_admin() function.
drop policy if exists "Admins manage customers" on public.customers;


-- public_listings: split SELECT by role. This avoids invoking a private-schema
-- helper for anon users and avoids auth.role(), which is deprecated.
drop policy if exists "Admins can manage listings" on public.public_listings;
drop policy if exists "admins_manage_listings" on public.public_listings;
drop policy if exists "Admins can delete listings" on public.public_listings;
drop policy if exists "Admins can insert listings" on public.public_listings;
drop policy if exists "Admins can read all listings" on public.public_listings;
drop policy if exists "Public can view published listings" on public.public_listings;
drop policy if exists "public_read_published_listings" on public.public_listings;
drop policy if exists "Admins can update listings" on public.public_listings;

create policy "public_listings_anon_select_published"
on public.public_listings
for select
to anon
using (is_published = true);

create policy "public_listings_authenticated_select_published_or_admin"
on public.public_listings
for select
to authenticated
using (is_published = true or (select private.is_admin()));

create policy "public_listings_insert_admin"
on public.public_listings
for insert
to authenticated
with check ((select private.is_admin()));

create policy "public_listings_update_admin"
on public.public_listings
for update
to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

create policy "public_listings_delete_admin"
on public.public_listings
for delete
to authenticated
using ((select private.is_admin()));


-- listing_images: mirror the listing visibility rules. Authenticated admins can
-- inspect unpublished listing images; all other users see published images only.
drop policy if exists "Admins can manage listing images" on public.listing_images;
drop policy if exists "Public can view listing images" on public.listing_images;

create policy "listing_images_anon_select_published"
on public.listing_images
for select
to anon
using (
  exists (
    select 1 from public.public_listings as l
    where l.id = listing_images.listing_id and l.is_published = true
  )
);

create policy "listing_images_authenticated_select_published_or_admin"
on public.listing_images
for select
to authenticated
using (
  exists (
    select 1 from public.public_listings as l
    where l.id = listing_images.listing_id
      and (l.is_published = true or (select private.is_admin()))
  )
);

create policy "listing_images_insert_admin"
on public.listing_images
for insert
to authenticated
with check ((select private.is_admin()));

create policy "listing_images_update_admin"
on public.listing_images
for update
to authenticated
using ((select private.is_admin()))
with check ((select private.is_admin()));

create policy "listing_images_delete_admin"
on public.listing_images
for delete
to authenticated
using ((select private.is_admin()));


-- Add indexes for the six foreign keys identified by the live Performance Advisor.
-- These support joins and parent-row updates/deletes; IF NOT EXISTS is repeat-safe.
create index if not exists listing_images_listing_id_idx
  on public.listing_images (listing_id);

create index if not exists public_listings_property_id_idx
  on public.public_listings (property_id);

create index if not exists transactions_customer_id_idx
  on public.transactions (customer_id);

create index if not exists transactions_property_id_idx
  on public.transactions (property_id);

create index if not exists visits_customer_id_idx
  on public.visits (customer_id);

create index if not exists visits_property_id_idx
  on public.visits (property_id);
