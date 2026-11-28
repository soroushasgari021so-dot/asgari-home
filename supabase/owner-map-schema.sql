-- ASGARI HOME: private owner contacts and public property coordinates
-- Apply only after reviewing this migration in the pull request.
-- Existing owner records remain private; public users only receive the owner UUID
-- on listing rows (not the owners table or its contact fields).

alter table public.public_listings
  add column if not exists owner_id uuid references public.owners(id) on delete set null,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

alter table public.public_listings
  drop constraint if exists public_listings_latitude_range_check,
  drop constraint if exists public_listings_longitude_range_check,
  drop constraint if exists public_listings_location_pair_check,
  add constraint public_listings_latitude_range_check
    check (latitude is null or latitude between -90 and 90),
  add constraint public_listings_longitude_range_check
    check (longitude is null or longitude between -180 and 180),
  add constraint public_listings_location_pair_check
    check ((latitude is null) = (longitude is null));

create index if not exists public_listings_owner_id_idx
  on public.public_listings(owner_id);

create index if not exists public_listings_published_location_idx
  on public.public_listings(is_published)
  where is_published = true and latitude is not null and longitude is not null;

-- Owner contact details are visible only to authenticated administrators.
alter table public.owners enable row level security;
revoke all on table public.owners from anon;
grant select, insert, update, delete on table public.owners to authenticated;

drop policy if exists "Public can view owners" on public.owners;
drop policy if exists "Anyone can read owners" on public.owners;

-- Preserve the existing administrator-only policy if it is already present.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'owners'
      and policyname = 'Admins can manage owners'
  ) then
    execute 'create policy "Admins can manage owners" on public.owners for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()))';
  end if;
end
$$;

comment on column public.public_listings.owner_id is
  'Private owner relation. Owner contact fields are stored in public.owners under administrator-only RLS.';
comment on column public.public_listings.latitude is
  'Public map latitude for the property location; must be paired with longitude.';
comment on column public.public_listings.longitude is
  'Public map longitude for the property location; must be paired with latitude.';
