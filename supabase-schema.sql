-- ============================================================
--  Twin Feed Monitor — schema v2 (households / profile sources)
--  One account owns many households. Each household has its own
--  babies, feed sessions, and settings. Every device signed into
--  the same email sees them all.
--
--  Paste this whole file into Supabase → SQL Editor → New query → Run.
--  (Safe to run on a fresh project. If you ran the old v1 schema,
--   see the note at the bottom.)
-- ============================================================

-- 1) Tables ---------------------------------------------------

create table if not exists households (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid not null references auth.users (id),
  name          text not null,
  alert_gap_min int default 180,
  created_at    timestamptz default now()
);

create table if not exists babies (
  id            uuid primary key default gen_random_uuid(),
  household_id  uuid not null references households (id) on delete cascade,
  owner_id      uuid not null references auth.users (id),
  name          text not null,
  color         text default 'A',           -- theme slot: A B C D
  dob           date,
  weight_kg     numeric,
  sort_order    int default 0,
  created_at    timestamptz default now()
);
create index if not exists babies_household_idx on babies (household_id);

create table if not exists sessions (
  id            bigint generated always as identity primary key,
  household_id  uuid not null references households (id) on delete cascade,
  baby_id       uuid not null references babies (id) on delete cascade,
  owner_id      uuid not null references auth.users (id),
  start_at      timestamptz not null,
  end_at        timestamptz not null,
  duration_min  numeric,
  ml            numeric,
  created_at    timestamptz default now()
);
create index if not exists sessions_household_idx on sessions (household_id);
create index if not exists sessions_end_idx on sessions (end_at);

-- 2) Row Level Security ---------------------------------------
alter table households enable row level security;
alter table babies    enable row level security;
alter table sessions  enable row level security;

-- Option-1 model: each user sees ONLY their own households (and the
-- babies/sessions inside them), from any number of devices signed in
-- as that same account.

create policy "own households" on households for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "own babies" on babies for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "own sessions" on sessions for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- 3) Realtime -------------------------------------------------
alter publication supabase_realtime add table sessions;
alter publication supabase_realtime add table babies;

-- ============================================================
--  Upgrading from the old v1 schema?
--  The v1 tables aren't compatible with households. On a fresh
--  start, drop them first (only if you don't need old test data):
--
--    drop table if exists profiles cascade;
--
--  Then run everything above.
-- ============================================================
