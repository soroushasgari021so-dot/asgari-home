-- Consolidate overlapping permissive RLS policies without changing intended access.
-- Reviewed against the live policy definitions on 2026-11-27.
-- Admin membership remains defined by private.is_admin().

-- admin_users: preserve self-read for non-admin authenticated users and full
-- management for admins, but avoid overlapping SELECT policies.
drop policy if exists "Admins can manage admin users" on public.admin_users;
drop policy if exists "admin_users_read_own" on public.admin_users;

create policy "admin_users_select_self_or_admin"
on public.admin_users
for select
to authenticated
using (user_id = (select auth.uid()) or private.is_admin());

create policy "admin_users_insert_admin"
on public.admin_users
for insert
to authenticated
with check (private.is_admin());

create policy "admin_users_update_admin"
on public.admin_users
for update
to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy "admin_users_delete_admin"
on public.admin_users
for delete
to authenticated
using (private.is_admin());


-- customers: two ALL policies expressed the same admin check. Keep the
-- private-schema predicate and remove the redundant EXISTS policy.
drop policy if exists "Admins manage customers" on public.customers;


-- public_listings: replace overlapping public-read and admin-ALL policies
-- with one SELECT policy and explicit admin write policies.
drop policy if exists "Admins can manage listings" on public.public_listings;
drop policy if exists "admins_manage_listings" on public.public_listings;
drop policy if exists "Admins can delete listings" on public.public_listings;
drop policy if exists "Admins can insert listings" on public.public_listings;
drop policy if exists "Admins can read all listings" on public.public_listings;
drop policy if exists "Public can view published listings" on public.public_listings;
drop policy if exists "public_read_published_listings" on public.public_listings;
drop policy if exists "Admins can update listings" on public.public_listings;

create policy "public_listings_select_published_or_admin"
on public.public_listings
for select
to anon, authenticated
using (
  is_published = true
  or (auth.role() = 'authenticated' and private.is_admin())
);

create policy "public_listings_insert_admin"
on public.public_listings
for insert
to authenticated
with check (private.is_admin());

create policy "public_listings_update_admin"
on public.public_listings
for update
to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy "public_listings_delete_admin"
on public.public_listings
for delete
to authenticated
using (private.is_admin());


-- listing_images: admins must be able to see images for unpublished listings;
-- public users may see images only when the parent listing is published.
-- A unified SELECT policy preserves both cases without permissive overlap.
drop policy if exists "Admins can manage listing images" on public.listing_images;
drop policy if exists "Public can view listing images" on public.listing_images;

create policy "listing_images_select_published_or_admin"
on public.listing_images
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.public_listings as l
    where l.id = listing_images.listing_id
      and (
        l.is_published = true
        or (auth.role() = 'authenticated' and private.is_admin())
      )
  )
);

create policy "listing_images_insert_admin"
on public.listing_images
for insert
to authenticated
with check (private.is_admin());

create policy "listing_images_update_admin"
on public.listing_images
for update
to authenticated
using (private.is_admin())
with check (private.is_admin());

create policy "listing_images_delete_admin"
on public.listing_images
for delete
to authenticated
using (private.is_admin());
