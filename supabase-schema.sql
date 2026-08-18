-- ============================================================
--  Baby Care Monitor - schema v4
--  Feeding (breast/expressed/formula) + Sleep + Diaper +
--  Weight/growth + Prescriptions (image storage).
--
--  Run in Supabase -> SQL Editor. If upgrading, run the DROP
--  block at the very bottom FIRST, then run everything above.
-- ============================================================

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
  sex           text default 'unknown' check (sex in ('boy','girl','unknown')),
  dob           date,
  weight_kg     numeric,          -- latest weight (also tracked over time in weights table)
  sort_order    int default 0,
  created_at    timestamptz default now()
);
create index if not exists babies_household_idx on babies (household_id);

-- Feeds: type = breast | expressed | formula ; side = L|R|null (breast only)
create table if not exists sessions (
  id            bigint generated always as identity primary key,
  household_id  uuid not null references households (id) on delete cascade,
  baby_id       uuid not null references babies (id) on delete cascade,
  owner_id      uuid not null references auth.users (id),
  feed_type     text not null default 'formula' check (feed_type in ('breast','expressed','formula')),
  side          text check (side in ('L','R')),
  start_at      timestamptz not null,
  end_at        timestamptz not null,
  duration_min  numeric,
  ml            numeric,          -- null for breast
  created_at    timestamptz default now()
);
create index if not exists sessions_household_idx on sessions (household_id);
create index if not exists sessions_end_idx on sessions (end_at);

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

-- Weight measurements over time (for growth chart)
create table if not exists weights (
  id            bigint generated always as identity primary key,
  household_id  uuid not null references households (id) on delete cascade,
  baby_id       uuid not null references babies (id) on delete cascade,
  owner_id      uuid not null references auth.users (id),
  at            date not null,
  weight_kg     numeric not null,
  created_at    timestamptz default now()
);
create index if not exists weights_baby_idx on weights (baby_id);

-- Prescriptions: metadata row; image lives in Storage bucket 'prescriptions'
create table if not exists prescriptions (
  id            bigint generated always as identity primary key,
  household_id  uuid not null references households (id) on delete cascade,
  baby_id       uuid references babies (id) on delete cascade,
  owner_id      uuid not null references auth.users (id),
  at            date not null,
  title         text,
  note          text,
  storage_path  text not null,     -- path within the 'prescriptions' bucket
  created_at    timestamptz default now()
);
create index if not exists prescriptions_household_idx on prescriptions (household_id);

-- Row Level Security ------------------------------------------
alter table households    enable row level security;
alter table babies        enable row level security;
alter table sessions      enable row level security;
alter table sleeps        enable row level security;
alter table diapers       enable row level security;
alter table weights       enable row level security;
alter table prescriptions enable row level security;

create policy "own households"    on households    for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own babies"        on babies        for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own sessions"      on sessions      for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own sleeps"        on sleeps        for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own diapers"       on diapers       for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own weights"       on weights       for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "own prescriptions" on prescriptions for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- Realtime ----------------------------------------------------
alter publication supabase_realtime add table sessions;
alter publication supabase_realtime add table sleeps;
alter publication supabase_realtime add table diapers;
alter publication supabase_realtime add table weights;
alter publication supabase_realtime add table babies;

-- ============================================================
--  STORAGE SETUP (do this in the dashboard, one time):
--  1. Left sidebar -> Storage -> New bucket
--     Name: prescriptions   |  Public: OFF (keep private)
--  2. Storage -> Policies -> on the 'prescriptions' bucket, add a
--     policy "own files" FOR ALL to role authenticated using:
--        (bucket_id = 'prescriptions' AND owner = auth.uid())
--     with check the same. (Supabase can template this for you:
--     choose "Give users access to own folder" style policy.)
-- ============================================================

-- ============================================================
--  UPGRADING FROM AN OLDER SCHEMA? Run this FIRST, alone, then
--  run everything above. Deletes old data - only if not needed.
--
--    drop table if exists prescriptions cascade;
--    drop table if exists weights   cascade;
--    drop table if exists diapers   cascade;
--    drop table if exists sleeps    cascade;
--    drop table if exists sessions  cascade;
--    drop table if exists profiles  cascade;
--    drop table if exists babies    cascade;
--    drop table if exists households cascade;
-- ============================================================
