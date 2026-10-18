-- Chess Plus online games: run this once in the Supabase SQL Editor.
-- One row per game; see res://scenes/online/online_session.gd for what each column means.

create table if not exists public.games (
  code        text primary key,
  white_id    text,
  black_id    text,
  white_army  jsonb,
  black_army  jsonb,
  time_ms     integer not null default 0,
  white_ms    integer not null default 0,
  black_ms    integer not null default 0,
  moves       jsonb   not null default '[]'::jsonb,
  move_count  integer not null default 0,
  status      text    not null default 'waiting',
  result      text    not null default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Keep updated_at current on every change.
create or replace function public.games_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists games_touch on public.games;
create trigger games_touch before update on public.games
for each row execute function public.games_touch();

-- The game (using the public key) may read, create and update games, but never delete them.
alter table public.games enable row level security;

drop policy if exists "read games" on public.games;
create policy "read games" on public.games for select to anon using (true);

drop policy if exists "create games" on public.games;
create policy "create games" on public.games for insert to anon with check (true);

drop policy if exists "update games" on public.games;
create policy "update games" on public.games for update to anon using (true) with check (true);

grant select, insert, update on public.games to anon;
