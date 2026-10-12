-- Bray Estate starter schema for Supabase Postgres.
-- Review with a database developer before production. Do not expose private tables to anon users.
create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create type public.inventory_kind as enum ('event_space', 'accommodation', 'estate');
create type public.booking_status as enum (
  'hold', 'pending_payment', 'confirmed', 'cancelled', 'expired', 'refunded'
);
create type public.booking_kind as enum ('event', 'stay', 'combined');

create table public.inventory (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  kind public.inventory_kind not null,
  active boolean not null default true,
  guest_capacity integer,
  timezone text not null default 'America/Chicago',
  description text,
  created_at timestamptz not null default now(),
  check (guest_capacity is null or guest_capacity > 0)
);

create table public.event_packages (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text,
  active boolean not null default true,
  base_price_cents integer not null check (base_price_cents >= 0),
  currency char(3) not null default 'USD',
  default_duration_hours numeric(5,2),
  max_guests integer,
  created_at timestamptz not null default now(),
  check (max_guests is null or max_guests > 0)
);

create table public.accommodation_rates (
  id uuid primary key default gen_random_uuid(),
  inventory_id uuid not null references public.inventory(id),
  rate_name text not null default 'Base rate',
  nightly_price_cents integer not null check (nightly_price_cents >= 0),
  currency char(3) not null default 'USD',
  starts_on date,
  ends_before date,
  minimum_nights integer not null default 1 check (minimum_nights > 0),
  active boolean not null default true,
  check (ends_before is null or starts_on is null or ends_before > starts_on)
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  public_reference text not null unique default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
  booking_kind public.booking_kind not null,
  status public.booking_status not null default 'hold',
  guest_name text not null,
  guest_email text not null,
  guest_phone text,
  guest_count integer not null check (guest_count > 0),
  event_package_id uuid references public.event_packages(id),
  notes text,
  currency char(3) not null default 'USD',
  subtotal_cents integer not null default 0 check (subtotal_cents >= 0),
  tax_cents integer not null default 0 check (tax_cents >= 0),
  discount_cents integer not null default 0 check (discount_cents >= 0),
  total_cents integer not null default 0 check (total_cents >= 0),
  deposit_due_cents integer not null default 0 check (deposit_due_cents >= 0),
  stripe_checkout_session_id text unique,
  stripe_payment_intent_id text,
  hold_expires_at timestamptz,
  confirmed_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (discount_cents <= subtotal_cents),
  check (deposit_due_cents <= total_cents)
);

create table public.booking_items (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  inventory_id uuid not null references public.inventory(id),
  -- Use [start,end): end is exclusive. For stays, set times to local check-in/check-out
  -- converted to timestamptz; for events, include setup/cleanup in the occupied range.
  occupied_period tstzrange not null,
  quantity integer not null default 1 check (quantity > 0),
  unit_price_cents integer not null check (unit_price_cents >= 0),
  line_total_cents integer not null check (line_total_cents >= 0),
  created_at timestamptz not null default now(),
  check (not isempty(occupied_period)),
  check (lower(occupied_period) < upper(occupied_period)),

);

-- Keep active inventory locks in this dedicated table. The exclusion constraint
-- below is the overlap guard; synchronize its status transactionally with bookings.
create table public.inventory_reservations (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  inventory_id uuid not null references public.inventory(id),
  occupied_period tstzrange not null,
  reservation_status public.booking_status not null default 'hold',
  hold_expires_at timestamptz,
  created_at timestamptz not null default now(),
  check (not isempty(occupied_period)),
  check (lower(occupied_period) < upper(occupied_period)),
  constraint no_overlapping_active_reservations
    exclude using gist (
      inventory_id with =,
      occupied_period with &&
    )
    where (reservation_status in ('hold', 'pending_payment', 'confirmed'))
);

create table public.availability_blocks (
  id uuid primary key default gen_random_uuid(),
  inventory_id uuid not null references public.inventory(id),
  occupied_period tstzrange not null,
  reason text not null,
  created_by text,
  created_at timestamptz not null default now(),
  check (not isempty(occupied_period)),
  check (lower(occupied_period) < upper(occupied_period))
);

create table public.booking_add_ons (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text,
  active boolean not null default true,
  price_cents integer not null check (price_cents >= 0),
  pricing_unit text not null check (pricing_unit in ('flat', 'per_guest', 'per_night', 'per_hour'))
);

create table public.booking_item_add_ons (
  booking_item_id uuid not null references public.booking_items(id) on delete cascade,
  add_on_id uuid not null references public.booking_add_ons(id),
  quantity numeric(8,2) not null default 1 check (quantity > 0),
  unit_price_cents integer not null check (unit_price_cents >= 0),
  line_total_cents integer not null check (line_total_cents >= 0),
  primary key (booking_item_id, add_on_id)
);

create table public.payment_events (
  id uuid primary key default gen_random_uuid(),
  stripe_event_id text not null unique,
  booking_id uuid references public.bookings(id),
  event_type text not null,
  processed_at timestamptz not null default now(),
  outcome text not null
);

create index bookings_status_hold_idx on public.bookings(status, hold_expires_at);
create index booking_items_booking_idx on public.booking_items(booking_id);
create index reservations_inventory_period_idx on public.inventory_reservations using gist (inventory_id, occupied_period);
create index availability_blocks_inventory_period_idx on public.availability_blocks using gist (inventory_id, occupied_period);

-- Important production notes:
-- 1. Apply RLS to all tables. Do not allow anonymous clients to insert confirmed bookings,
--    set prices/status, read guest PII, or read Stripe identifiers.
-- 2. Expose only server-side Edge Functions for availability checks and booking creation.
-- 3. Use a transaction/SECURITY DEFINER function to atomically create the booking and
--    reservation rows; catch exclusion violations and return "dates unavailable".
-- 4. Keep inventory_reservations.reservation_status synchronized with booking status in
--    the same transaction and expire old holds via scheduled cleanup.
-- 5. Convert local check-in/out and event times to UTC using the property's confirmed IANA
--    timezone. Use half-open ranges [start,end) so back-to-back stays can be possible.
-- 6. The exclusion constraint on inventory_reservations is the overlap protection.
