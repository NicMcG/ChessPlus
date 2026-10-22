-- Chess Plus online update 3: safe for anyone on the internet (Oct 2026).
--
-- BEFORE running this: in the Supabase dashboard, Authentication > Sign In /
-- Providers (or Authentication > Settings), turn on "Allow anonymous sign-ins".
-- The game signs every device in anonymously (no email, nothing for the player
-- to do), so the server knows who is who.
--
-- Then run this once in the SQL Editor (after supabase_setup.sql and updates 1
-- and 2).
--
-- What changes: nobody can read or change the tables directly any more. Every
-- action goes through one of the functions below, which checks it's allowed
-- (you're a player in this game, it's your turn, the game isn't over, not too
-- fast), and player IDs never leave the server. Clocks are kept by the server.
-- Copies of the game from before this update can't play online until they
-- update themselves (they do at the main menu).
--
-- Banning a device: add its ID (from games.white_id / black_id) to the
-- "banned" table in the Table Editor.

create schema if not exists chessplus_private;
revoke all on schema chessplus_private from public, anon, authenticated;

alter table public.games add column if not exists version integer not null default 0;
alter table public.games add column if not exists turn_started_at timestamptz;
alter table public.games add column if not exists created_by text;
alter table public.shared_armies add column if not exists owner_id text;
create index if not exists games_created_by on public.games (created_by, created_at);
create index if not exists games_updated_at on public.games (updated_at);
create index if not exists shared_armies_owner on public.shared_armies (owner_id, created_at);

create table if not exists public.banned (
  user_id     text primary key,
  reason      text not null default '',
  created_at  timestamptz not null default now()
);
alter table public.banned enable row level security;

-- Every change bumps the version, so the game can ask "anything new?" cheaply.
create or replace function public.games_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  new.version = old.version + 1;
  return new;
end $$;

-- No direct access to the tables any more.
drop policy if exists "read games" on public.games;
drop policy if exists "create games" on public.games;
drop policy if exists "update games" on public.games;
drop policy if exists "read shared armies" on public.shared_armies;
drop policy if exists "share armies" on public.shared_armies;
revoke all on public.games, public.shared_armies, public.banned from anon, authenticated;
drop function if exists public.post_chat(text, text, text);

-- --- Helpers (not reachable from the app) -----------------------------------------

-- Who is calling, or an error if they aren't signed in or are banned.
create or replace function chessplus_private.me() returns text
language plpgsql stable set search_path = '' as $$
declare
  uid text := auth.uid()::text;
begin
  if uid is null then
    raise exception 'Please sign in again.';
  end if;
  if exists (select 1 from public.banned b where b.user_id = uid) then
    raise exception 'This device can''t play online.';
  end if;
  return uid;
end $$;

-- Milliseconds since `t` (0 if null).
create or replace function chessplus_private.ms_since(t timestamptz) returns bigint
language sql stable set search_path = '' as $$
  select case when t is null then 0 else greatest(0, (extract(epoch from (now() - t)) * 1000)::bigint) end;
$$;

-- What a player (or someone with the code) sees of a game: never the IDs; the
-- chat, draw offer and rematch only for the game's players.
create or replace function chessplus_private.view(g public.games, viewer text) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'code', g.code, 'status', g.status, 'result', g.result, 'version', g.version,
    'time_ms', g.time_ms, 'white_ms', g.white_ms, 'black_ms', g.black_ms,
    'moves', g.moves, 'move_count', g.move_count, 'eval_bar', g.eval_bar,
    'white_army', g.white_army, 'black_army', g.black_army,
    'white_taken', coalesce(g.white_id, '') <> '',
    'black_taken', coalesce(g.black_id, '') <> '',
    'turn_ms', case when g.status = 'playing' then chessplus_private.ms_since(g.turn_started_at) else 0 end,
    'you', to_jsonb(array_remove(array[
        case when g.white_id = viewer then 'white' end,
        case when g.black_id = viewer then 'black' end], null)),
    'chat', case when viewer in (g.white_id, g.black_id) then g.chat else '[]'::jsonb end,
    'draw_offer', case when viewer in (g.white_id, g.black_id) then g.draw_offer else '' end,
    'rematch', case when viewer in (g.white_id, g.black_id) then g.rematch else '' end
  );
$$;

-- An army the server will store: the right shape and size. (Whether it keeps
-- the army rules is the referee's job, coming next.)
create or replace function chessplus_private.army_ok(a jsonb) returns boolean
language sql immutable set search_path = '' as $$
  select a is not null and jsonb_typeof(a) = 'object'
    and octet_length(a::text) <= 3000
    and jsonb_typeof(a->'pieces') = 'array'
    and jsonb_array_length(a->'pieces') between 1 and 16
    and (a->'name' is null or jsonb_typeof(a->'name') = 'string')
    and length(coalesce(a->>'name', '')) <= 40
    and not exists (
      select 1 from jsonb_array_elements(a->'pieces') p
      where jsonb_typeof(p) <> 'array' or jsonb_array_length(p) <> 3
        or jsonb_typeof(p->0) <> 'string' or length(p->>0) > 30
        or (case when jsonb_typeof(p->1) = 'number' then (p->>1)::numeric else -1 end) not in (0, 1, 2, 3, 4, 5, 6, 7)
        or (case when jsonb_typeof(p->2) = 'number' then (p->>2)::numeric else -1 end) not in (0, 1));
$$;

-- A new 5-character code not yet used in `tbl` ('games' or 'shared_armies').
create or replace function chessplus_private.new_code(tbl text) returns text
language plpgsql volatile set search_path = '' as $$
declare
  letters constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  c text;
begin
  loop
    c := '';
    for i in 1..5 loop
      c := c || substr(letters, 1 + floor(random() * 32)::int, 1);
    end loop;
    if tbl = 'games' then
      exit when not exists (select 1 from public.games g where g.code = c);
    else
      exit when not exists (select 1 from public.shared_armies s where s.code = c);
    end if;
  end loop;
  return c;
end $$;

-- Clear old games away so the database never fills up.
create or replace function chessplus_private.cleanup() returns void
language sql volatile set search_path = '' as $$
  delete from public.games where code in (
    select code from public.games
     where (status = 'waiting' and updated_at < now() - interval '1 day')
        or (status <> 'waiting' and updated_at < now() - interval '30 days')
     limit 200);
$$;

-- The caller's game, locked for changing, after checking `seat` is theirs.
create or replace function chessplus_private.my_game(p_code text, p_seat text) returns public.games
language plpgsql volatile set search_path = '' as $$
declare
  uid text := chessplus_private.me();
  g public.games;
begin
  select * into g from public.games where code = upper(btrim(p_code)) for update;
  if not found then
    raise exception 'There''s no game with the code %.', upper(btrim(p_code));
  end if;
  if p_seat is null or p_seat not in ('white', 'black')
     or (p_seat = 'white' and coalesce(g.white_id, '') <> uid)
     or (p_seat = 'black' and coalesce(g.black_id, '') <> uid) then
    raise exception 'You''re not a player in that game.';
  end if;
  return g;
end $$;

-- Whose move it is.
create or replace function chessplus_private.mover(g public.games) returns text
language sql immutable set search_path = '' as $$
  select case when g.move_count % 2 = 0 then 'white' else 'black' end;
$$;

-- --- What the app can do ---------------------------------------------------------------

-- Create a game. p_seat: 'white', 'black' or 'random'. Both armies are sent
-- (they can differ, "Default" depends on the side); the one for the side the
-- creator gets is kept.
create or replace function public.create_game(p_seat text, p_white_army jsonb, p_black_army jsonb,
    p_time_ms integer, p_eval_bar boolean default false) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.me();
  seat text := p_seat;
  g public.games;
begin
  if seat = 'random' then
    seat := case when random() < 0.5 then 'white' else 'black' end;
  end if;
  if seat is null or seat not in ('white', 'black') then
    raise exception 'Choose White, Black or Random.';
  end if;
  if p_time_ms is null or p_time_ms not in (0, 180000, 300000, 600000, 900000, 1800000) then
    raise exception 'That time limit isn''t one of the choices.';
  end if;
  if not chessplus_private.army_ok(case when seat = 'white' then p_white_army else p_black_army end) then
    raise exception 'That army can''t be used online.';
  end if;
  if (select count(*) from public.games where created_by = uid and created_at > now() - interval '1 hour') >= 30 then
    raise exception 'Too many new games: try again in a while.';
  end if;
  if (select count(*) from public.games where created_by = uid and status = 'waiting') >= 5 then
    raise exception 'You already have 5 games waiting for an opponent.';
  end if;
  perform chessplus_private.cleanup();
  insert into public.games (code, status, result, time_ms, white_ms, black_ms, moves, move_count,
      eval_bar, created_by, white_id, black_id, white_army, black_army)
    values (chessplus_private.new_code('games'), 'waiting', '', p_time_ms, p_time_ms, p_time_ms,
      '[]'::jsonb, 0, coalesce(p_eval_bar, false), uid,
      case when seat = 'white' then uid end, case when seat = 'black' then uid end,
      case when seat = 'white' then p_white_army end, case when seat = 'black' then p_black_army end)
    returning * into g;
  return chessplus_private.view(g, uid);
end $$;

-- Join a waiting game by its code: the free side is yours ('seat' in the reply).
create or replace function public.join_game(p_code text, p_white_army jsonb, p_black_army jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.me();
  c text := upper(btrim(p_code));
  g public.games;
  seat text;
begin
  select * into g from public.games where code = c for update;
  if not found then
    raise exception 'There''s no game with the code %.', c;
  end if;
  if g.status = 'cancelled' then
    raise exception 'That game was cancelled.';
  end if;
  if g.status <> 'waiting' then
    raise exception 'That game has already started.';
  end if;
  seat := case when coalesce(g.white_id, '') = '' then 'white' else 'black' end;
  if not chessplus_private.army_ok(case when seat = 'white' then p_white_army else p_black_army end) then
    raise exception 'That army can''t be used online.';
  end if;
  update public.games set
      white_id = case when seat = 'white' then uid else white_id end,
      white_army = case when seat = 'white' then p_white_army else white_army end,
      black_id = case when seat = 'black' then uid else black_id end,
      black_army = case when seat = 'black' then p_black_army else black_army end,
      status = 'playing', turn_started_at = now()
    where code = c returning * into g;
  return chessplus_private.view(g, uid) || jsonb_build_object('seat', seat);
end $$;

-- A game as the caller may see it; null if there's no such game. With the
-- version the caller already has, only {"version", "unchanged"} comes back.
create or replace function public.get_game(p_code text, p_known_version integer default -1) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  uid text := auth.uid()::text;
  g public.games;
begin
  if uid is null then
    raise exception 'Please sign in again.';
  end if;
  select * into g from public.games where code = upper(btrim(p_code));
  if not found then
    return null;
  end if;
  if g.version = p_known_version then
    return jsonb_build_object('version', g.version, 'unchanged', true);
  end if;
  return chessplus_private.view(g, uid);
end $$;

-- Play a move (as Move.to_text()). Only on your turn, and only if the game is
-- still at p_expected moves (so two moves can never collide): otherwise null.
-- The server's clock decides the time used, allowing up to 2.5 s for the
-- delay in hearing about the opponent's move (p_think_ms = the time the player
-- saw). p_finished: the move ended the game on the board.
create or replace function public.play_move(p_code text, p_seat text, p_move text, p_expected integer,
    p_think_ms integer, p_finished boolean default false) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  g public.games := chessplus_private.my_game(p_code, p_seat);
  uid text := chessplus_private.me();
  mover text := chessplus_private.mover(g);
  elapsed bigint;
  charged bigint;
  left_ms integer := 0;
begin
  if g.status <> 'playing' or g.move_count <> p_expected or p_seat <> mover then
    return null;
  end if;
  if p_move is null or p_move !~ '^[A-Za-z0-9!=@~x-]{2,16}$' or g.move_count >= 1000 then
    raise exception 'That move can''t be sent.';
  end if;
  if g.time_ms > 0 then
    elapsed := chessplus_private.ms_since(g.turn_started_at);
    charged := least(elapsed, greatest(greatest(coalesce(p_think_ms, 0), 0), elapsed - 2500));
    left_ms := (case when mover = 'white' then g.white_ms else g.black_ms end) - charged;
    if left_ms <= 0 then
      update public.games set status = 'finished', result = mover || '_timeout',
          white_ms = case when mover = 'white' then 0 else white_ms end,
          black_ms = case when mover = 'black' then 0 else black_ms end
        where code = g.code returning * into g;
      return chessplus_private.view(g, uid);
    end if;
  end if;
  update public.games set
      moves = moves || to_jsonb(p_move), move_count = move_count + 1,
      white_ms = case when mover = 'white' and time_ms > 0 then left_ms else white_ms end,
      black_ms = case when mover = 'black' and time_ms > 0 then left_ms else black_ms end,
      -- Moving instead of answering turns down the opponent's draw offer.
      draw_offer = case when draw_offer <> mover then '' else draw_offer end,
      turn_started_at = now(),
      status = case when coalesce(p_finished, false) then 'finished' else status end,
      result = case when coalesce(p_finished, false) then 'board' else result end
    where code = g.code returning * into g;
  return chessplus_private.view(g, uid);
end $$;

create or replace function public.resign_game(p_code text, p_seat text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  g public.games := chessplus_private.my_game(p_code, p_seat);
begin
  if g.status <> 'playing' then
    return null;
  end if;
  update public.games set status = 'finished', result = p_seat || '_resigned', draw_offer = ''
    where code = g.code returning * into g;
  return chessplus_private.view(g, chessplus_private.me());
end $$;

create or replace function public.offer_draw(p_code text, p_seat text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  g public.games := chessplus_private.my_game(p_code, p_seat);
begin
  if g.status <> 'playing' or g.draw_offer <> '' then
    return null;
  end if;
  update public.games set draw_offer = p_seat where code = g.code returning * into g;
  return chessplus_private.view(g, chessplus_private.me());
end $$;

-- Answer the opponent's draw offer.
create or replace function public.answer_draw(p_code text, p_seat text, p_accept boolean) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  g public.games := chessplus_private.my_game(p_code, p_seat);
begin
  if g.draw_offer = '' or g.draw_offer = p_seat then
    return null;
  end if;
  if p_accept and g.status = 'playing' then
    update public.games set status = 'finished', result = 'draw_agreed', draw_offer = ''
      where code = g.code returning * into g;
  else
    update public.games set draw_offer = '' where code = g.code returning * into g;
  end if;
  return chessplus_private.view(g, chessplus_private.me());
end $$;

-- Give up waiting for an opponent (only before anyone has joined).
create or replace function public.cancel_game(p_code text, p_seat text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  g public.games := chessplus_private.my_game(p_code, p_seat);
begin
  if g.status <> 'waiting' then
    return null;
  end if;
  update public.games set status = 'cancelled' where code = g.code returning * into g;
  return chessplus_private.view(g, chessplus_private.me());
end $$;

-- The side to move has run out of time (by the server's clock): end the game.
-- The opponent's claim waits the same 2.5 s a late move is allowed. Returns
-- the game either way (still on if the time isn't up).
create or replace function public.claim_timeout(p_code text, p_seat text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  g public.games := chessplus_private.my_game(p_code, p_seat);
  mover text := chessplus_private.mover(g);
  grace integer := case when p_seat = mover then 0 else 2500 end;
begin
  if g.status = 'playing' and g.time_ms > 0
     and chessplus_private.ms_since(g.turn_started_at) > (case when mover = 'white' then g.white_ms else g.black_ms end) + grace then
    update public.games set status = 'finished', result = mover || '_timeout',
        white_ms = case when mover = 'white' then 0 else white_ms end,
        black_ms = case when mover = 'black' then 0 else black_ms end
      where code = g.code returning * into g;
  end if;
  return chessplus_private.view(g, chessplus_private.me());
end $$;

-- Add a chat message: up to 200 characters, at most 5 every 10 seconds, 300 a game.
create or replace function public.send_chat(p_code text, p_seat text, p_text text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  g public.games := chessplus_private.my_game(p_code, p_seat);
  msg text := left(btrim(regexp_replace(coalesce(p_text, ''), '[[:cntrl:]]', ' ', 'g')), 200);
  now_ms bigint := (extract(epoch from now()) * 1000)::bigint;
begin
  if msg = '' then
    raise exception 'Empty message.';
  end if;
  if jsonb_array_length(g.chat) >= 300 then
    raise exception 'This game''s chat is full.';
  end if;
  if (select count(*) from jsonb_array_elements(g.chat) m
       where m->>'from' = p_seat and coalesce((m->>'at')::bigint, 0) > now_ms - 10000) >= 5 then
    raise exception 'You''re sending messages too fast.';
  end if;
  update public.games
     set chat = chat || jsonb_build_array(jsonb_build_object('from', p_seat, 'text', msg, 'at', now_ms))
   where code = g.code returning * into g;
  return chessplus_private.view(g, chessplus_private.me());
end $$;

-- Point a finished game at its rematch (p_new_code, a waiting game the caller
-- created). Null if the other player got there first: join theirs instead.
create or replace function public.claim_rematch(p_code text, p_seat text, p_new_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  g public.games := chessplus_private.my_game(p_code, p_seat);
  uid text := chessplus_private.me();
begin
  if g.status <> 'finished' or g.rematch <> '' then
    return null;
  end if;
  if not exists (select 1 from public.games n
                  where n.code = upper(btrim(p_new_code)) and n.created_by = uid and n.status = 'waiting') then
    raise exception 'That rematch game isn''t yours.';
  end if;
  update public.games set rematch = upper(btrim(p_new_code)) where code = g.code returning * into g;
  return chessplus_private.view(g, uid);
end $$;

-- Share an army: returns {"code": ...}. At most 20 an hour from one device.
create or replace function public.share_army(p_army jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.me();
  c text;
begin
  if not chessplus_private.army_ok(p_army) then
    raise exception 'That army can''t be shared.';
  end if;
  if (select count(*) from public.shared_armies where owner_id = uid and created_at > now() - interval '1 hour') >= 20 then
    raise exception 'Too many shared armies: try again in a while.';
  end if;
  c := chessplus_private.new_code('shared_armies');
  insert into public.shared_armies (code, army, owner_id) values (c, p_army, uid);
  return jsonb_build_object('code', c);
end $$;

-- A shared army by its code ({"army": ...}), or null.
create or replace function public.get_shared_army(p_code text) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  a jsonb;
begin
  if auth.uid() is null then
    raise exception 'Please sign in again.';
  end if;
  select s.army into a from public.shared_armies s where s.code = upper(btrim(p_code));
  if a is null then
    return null;
  end if;
  return jsonb_build_object('army', a);
end $$;

-- Only signed-in players may call these; nobody can call the helpers.
revoke all on all functions in schema chessplus_private from public, anon, authenticated;
revoke all on function
  public.create_game(text, jsonb, jsonb, integer, boolean),
  public.join_game(text, jsonb, jsonb),
  public.get_game(text, integer),
  public.play_move(text, text, text, integer, integer, boolean),
  public.resign_game(text, text),
  public.offer_draw(text, text),
  public.answer_draw(text, text, boolean),
  public.cancel_game(text, text),
  public.claim_timeout(text, text),
  public.send_chat(text, text, text),
  public.claim_rematch(text, text, text),
  public.share_army(jsonb),
  public.get_shared_army(text),
  public.games_touch()
  from public, anon;
grant execute on function
  public.create_game(text, jsonb, jsonb, integer, boolean),
  public.join_game(text, jsonb, jsonb),
  public.get_game(text, integer),
  public.play_move(text, text, text, integer, integer, boolean),
  public.resign_game(text, text),
  public.offer_draw(text, text),
  public.answer_draw(text, text, boolean),
  public.cancel_game(text, text),
  public.claim_timeout(text, text),
  public.send_chat(text, text, text),
  public.claim_rematch(text, text, text),
  public.share_army(jsonb),
  public.get_shared_army(text)
  to authenticated;
