-- ============================================================
--  Baby Care Monitor - schema v3 (feed + sleep + diaper)
--  One account owns many households ("profiles"). Each holds its
--  own babies, and each baby has feed / sleep / diaper events.
--
--  Paste into Supabase -> SQL Editor -> New query -> Run.
--  If upgrading from an older schema, run the DROP block at the
--  bottom FIRST (only if you don't need the old test data).
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
  color         text default 'A',
  dob           date,
  weight_kg     numeric,
  sort_order    int default 0,
  created_at    timestamptz default now()
);
create index if not exists babies_household_idx on babies (household_id);

-- Feeds
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

-- Sleep stretches
create table if not exists sleeps (
  id            bigint generated always as identity primary key,
  household_id  uuid not null references households (id) on delete cascade,
  baby_id       uuid not null references babies (id) on delete cascade,
  owner_id      uuid not null references auth.users (id),
  start_at      timestamptz not null,
  end_at        timestamptz not null,
  duration_min  numeric,
  created_at    timestamptz default now()
);
create index if not exists sleeps_household_idx on sleeps (household_id);
create index if not exists sleeps_end_idx on sleeps (end_at);

-- Diaper changes (instant events)
create table if not exists diapers (
  id            bigint generated always as identity primary key,
  household_id  uuid not null references households (id) on delete cascade,
  baby_id       uuid not null references babies (id) on delete cascade,
  owner_id      uuid not null references auth.users (id),
  at            timestamptz not null,
  kind          text not null check (kind in ('wet','dirty','both')),
  created_at    timestamptz default now()
);
create index if not exists diapers_household_idx on diapers (household_id);
create index if not exists diapers_at_idx on diapers (at);

-- 2) Row Level Security ---------------------------------------
alter table households enable row level security;
alter table babies    enable row level security;
alter table sessions  enable row level security;
alter table sleeps    enable row level security;
alter table diapers   enable row level security;

create policy "own households" on households for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own babies" on babies for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own sessions" on sessions for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own sleeps" on sleeps for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own diapers" on diapers for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- 3) Realtime -------------------------------------------------
alter publication supabase_realtime add table sessions;
alter publication supabase_realtime add table sleeps;
alter publication supabase_realtime add table diapers;
alter publication supabase_realtime add table babies;

-- ============================================================
--  UPGRADING? Run this FIRST, on its own, then run everything
--  above. Deletes old data - only if you don't need it.
--
--    drop table if exists diapers  cascade;
--    drop table if exists sleeps   cascade;
--    drop table if exists sessions cascade;
--    drop table if exists profiles cascade;
--    drop table if exists babies   cascade;
--    drop table if exists households cascade;
-- ============================================================
