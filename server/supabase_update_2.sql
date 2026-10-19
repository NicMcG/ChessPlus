-- Chess Plus online update 2: sharing armies by code.
-- Run once in the Supabase SQL Editor (after supabase_setup.sql and supabase_update_1.sql).
--
-- One row per shared army: a 5-letter code and the army as plain data (see
-- SavedGame.army_to_dict). The game (using the public key) may add a shared
-- army and read one by its code, but never change or delete one.

create table if not exists public.shared_armies (
  code        text primary key,
  army        jsonb not null,
  created_at  timestamptz not null default now()
);

alter table public.shared_armies enable row level security;

drop policy if exists "read shared armies" on public.shared_armies;
create policy "read shared armies" on public.shared_armies for select to anon using (true);

drop policy if exists "share armies" on public.shared_armies;
create policy "share armies" on public.shared_armies for insert to anon with check (true);

grant select, insert on public.shared_armies to anon;
