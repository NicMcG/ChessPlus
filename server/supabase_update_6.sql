-- Chess Plus online update 6: bonus time and live counts (Oct 2026).
--
-- Run once in the SQL Editor right after the referee is uploaded with bonus
-- time (tools/deploy_referee.sh), after updates 3, 4 and 5.
--
-- Bonus time (Mac's full set, written "3+2": 3 minutes each, 2 seconds added
-- after each of your moves): No time limit, 1+0, 1+1, 2+1, 3+0, 3+2, 5+0, 5+3,
-- 10+0, 10+5, 15+10, 30+0, 30+20. In Quick match both the minutes and the
-- bonus must fit (or one player picked Any; Any with Any plays 10+0).
--
-- Live counts: how many players are online (on Play online or in an online
-- game in the last minute) and how many are waiting for a quick match.

-- All or nothing: if any line fails, nothing changes.
begin;

alter table public.games add column if not exists increment_ms integer not null default 0;
alter table public.match_queue add column if not exists increment_ms integer not null default 0;

create table if not exists public.presence (
  user_id  text primary key,
  seen_at  timestamptz not null default now()
);
alter table public.presence enable row level security;
revoke all on public.presence from anon, authenticated;

-- One of the game's time controls (milliseconds each, bonus per move).
create or replace function chessplus_private.time_ok(base integer, bonus integer) returns boolean
language sql immutable set search_path = '' as $$
  select (base, bonus) in ((0, 0), (60000, 0), (60000, 1000), (120000, 1000), (180000, 0), (180000, 2000),
    (300000, 0), (300000, 3000), (600000, 0), (600000, 5000), (900000, 10000), (1800000, 0), (1800000, 20000));
$$;

-- Note that a player is here (at most every 30 seconds, to keep writes few).
create or replace function chessplus_private.seen(uid text) returns void
language sql volatile set search_path = '' as $$
  insert into public.presence (user_id, seen_at) values (uid, now())
  on conflict (user_id) do update set seen_at = now()
    where public.presence.seen_at < now() - interval '30 seconds';
$$;

-- The game as the caller may see it: now with the bonus.
create or replace function chessplus_private.view(g public.games, viewer text) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'code', g.code, 'status', g.status, 'result', g.result, 'version', g.version,
    'time_ms', g.time_ms, 'increment_ms', g.increment_ms, 'white_ms', g.white_ms, 'black_ms', g.black_ms,
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

-- get_game also notes the player is online (it's what an online game polls).
create or replace function public.get_game(p_code text, p_known_version integer default -1) returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  uid text := auth.uid()::text;
  g public.games;
begin
  if uid is null then
    raise exception 'Please sign in again.';
  end if;
  perform chessplus_private.seen(uid);
  select * into g from public.games where code = upper(btrim(p_code));
  if not found then
    return null;
  end if;
  if g.version = p_known_version then
    return jsonb_build_object('version', g.version, 'unchanged', true);
  end if;
  return chessplus_private.view(g, uid);
end $$;

-- Live counts for Play online (and notes the caller is online).
create or replace function public.online_counts() returns jsonb
language plpgsql volatile security definer set search_path = '' as $$
declare
  uid text := chessplus_private.me();
begin
  perform chessplus_private.seen(uid);
  delete from public.presence where seen_at < now() - interval '1 day';
  return jsonb_build_object(
    'online', (select count(*) from public.presence where seen_at > now() - interval '60 seconds'),
    'looking', (select count(*) from public.match_queue where game_code is null and seen_at > now() - interval '20 seconds'));
end $$;

-- Create a game: now with a bonus per move.
drop function if exists public.referee_create_game(text, text, jsonb, jsonb, integer, boolean, text);
create or replace function public.referee_create_game(p_user text, p_seat text, p_white_army jsonb,
    p_black_army jsonb, p_time_ms integer, p_increment_ms integer, p_eval_bar boolean, p_rules text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.player(p_user);
  g public.games;
begin
  if p_seat is null or p_seat not in ('white', 'black') then
    raise exception 'Choose White, Black or Random.';
  end if;
  if not chessplus_private.time_ok(p_time_ms, coalesce(p_increment_ms, 0)) then
    raise exception 'That time limit isn''t one of the choices.';
  end if;
  if not chessplus_private.army_ok(case when p_seat = 'white' then p_white_army else p_black_army end) then
    raise exception 'That army can''t be used online.';
  end if;
  if (select count(*) from public.games where created_by = uid and created_at > now() - interval '1 hour') >= 30 then
    raise exception 'Too many new games: try again in a while.';
  end if;
  if (select count(*) from public.games where created_by = uid and status = 'waiting') >= 5 then
    raise exception 'You already have 5 games waiting for an opponent.';
  end if;
  perform chessplus_private.cleanup();
  insert into public.games (code, status, result, time_ms, increment_ms, white_ms, black_ms, moves, move_count,
      eval_bar, created_by, white_id, black_id, white_army, black_army, rules)
    values (chessplus_private.new_code('games'), 'waiting', '', p_time_ms, coalesce(p_increment_ms, 0),
      p_time_ms, p_time_ms, '[]'::jsonb, 0, coalesce(p_eval_bar, false), uid,
      case when p_seat = 'white' then uid end, case when p_seat = 'black' then uid end,
      case when p_seat = 'white' then p_white_army end, case when p_seat = 'black' then p_black_army end,
      coalesce(p_rules, ''))
    returning * into g;
  return chessplus_private.view(g, uid);
end $$;

-- Play a move: as before, and the bonus is added to the mover's clock.
create or replace function public.referee_play_move(p_user text, p_code text, p_seat text, p_move text,
    p_expected integer, p_think_ms integer, p_finished boolean, p_refereed boolean) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.player(p_user);
  g public.games := chessplus_private.seat_game(chessplus_private.player(p_user), p_code, p_seat);
  mover text := chessplus_private.mover(g);
  elapsed bigint;
  charged bigint;
  left_ms integer := 0;
begin
  if g.status <> 'playing' or g.move_count <> p_expected or p_seat <> mover then
    return null;
  end if;
  if p_move is null or p_move !~ '^[A-Za-z0-9!=@~x/-]{2,20}$' or g.move_count >= 1000 then
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
    left_ms := left_ms + g.increment_ms;
  end if;
  update public.games set
      moves = moves || to_jsonb(p_move), move_count = move_count + 1,
      white_ms = case when mover = 'white' and time_ms > 0 then left_ms else white_ms end,
      black_ms = case when mover = 'black' and time_ms > 0 then left_ms else black_ms end,
      draw_offer = case when draw_offer <> mover then '' else draw_offer end,
      turn_started_at = now(),
      refereed = refereed and coalesce(p_refereed, false),
      status = case when coalesce(p_finished, false) then 'finished' else status end,
      result = case when coalesce(p_finished, false) then 'board' else result end
    where code = g.code returning * into g;
  return chessplus_private.view(g, uid);
end $$;

-- Quick match with bonus time: the minutes and the bonus must both fit (or
-- one side picked Any, time_ms -1).
drop function if exists chessplus_private.quick_candidates(text, integer, text);
create or replace function chessplus_private.quick_candidates(uid text, p_time_ms integer, p_increment_ms integer, p_rules text)
returns setof public.match_queue
language sql stable set search_path = '' as $$
  select * from public.match_queue q
   where q.user_id <> uid and q.game_code is null and q.rules = p_rules
     and q.seen_at > now() - interval '20 seconds'
     and ((q.time_ms = p_time_ms and q.increment_ms = p_increment_ms) or q.time_ms = -1 or p_time_ms = -1)
   order by q.entered_at
   limit 5;
$$;

drop function if exists public.referee_quick_enter(text, jsonb, jsonb, integer, text);
create or replace function public.referee_quick_enter(p_user text, p_white_army jsonb, p_black_army jsonb,
    p_time_ms integer, p_increment_ms integer, p_rules text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.player(p_user);
  mine public.match_queue;
  bonus integer := case when p_time_ms = -1 then 0 else coalesce(p_increment_ms, 0) end;
begin
  if p_time_ms is null or (p_time_ms <> -1 and not chessplus_private.time_ok(p_time_ms, bonus)) then
    raise exception 'That time limit isn''t one of the choices.';
  end if;
  if not chessplus_private.army_ok(p_white_army) or not chessplus_private.army_ok(p_black_army) then
    raise exception 'That army can''t be used online.';
  end if;
  perform chessplus_private.seen(uid);
  delete from public.match_queue where seen_at < now() - interval '1 hour';
  select * into mine from public.match_queue where user_id = uid;
  if found and mine.game_code is not null then
    delete from public.match_queue where user_id = uid;
    return jsonb_build_object('code', mine.game_code);
  end if;
  insert into public.match_queue (user_id, white_army, black_army, time_ms, increment_ms, rules)
    values (uid, p_white_army, p_black_army, p_time_ms, bonus, p_rules)
    on conflict (user_id) do update set white_army = excluded.white_army, black_army = excluded.black_army,
      time_ms = excluded.time_ms, increment_ms = excluded.increment_ms, rules = excluded.rules,
      game_code = null, seen_at = now();
  return jsonb_build_object('candidates', coalesce((
    select jsonb_agg(jsonb_build_object('user_id', c.user_id, 'white_army', c.white_army,
             'black_army', c.black_army, 'time_ms', c.time_ms))
      from chessplus_private.quick_candidates(uid, p_time_ms, bonus, p_rules) c), '[]'::jsonb));
end $$;

create or replace function public.referee_quick_pair(p_user text, p_other text, p_white_user text,
    p_finished boolean, p_refereed boolean) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.player(p_user);
  mine public.match_queue;
  theirs public.match_queue;
  white_row public.match_queue;
  black_row public.match_queue;
  t integer;
  bonus integer;
  g public.games;
begin
  -- One pairing at a time, so two players can't both take the same opponent.
  perform pg_advisory_xact_lock(4242);
  select * into mine from public.match_queue where user_id = uid and game_code is null;
  select * into theirs from public.match_queue
   where user_id = p_other and game_code is null and seen_at > now() - interval '20 seconds';
  if mine.user_id is null or theirs.user_id is null or mine.rules <> theirs.rules
     or not ((mine.time_ms = theirs.time_ms and mine.increment_ms = theirs.increment_ms)
             or mine.time_ms = -1 or theirs.time_ms = -1)
     or exists (select 1 from public.banned b where b.user_id = p_other) then
    return null;
  end if;
  if mine.time_ms >= 0 then
    t := mine.time_ms; bonus := mine.increment_ms;
  elsif theirs.time_ms >= 0 then
    t := theirs.time_ms; bonus := theirs.increment_ms;
  else
    t := 600000; bonus := 0;
  end if;
  if p_white_user = uid then
    white_row := mine; black_row := theirs;
  else
    white_row := theirs; black_row := mine;
  end if;
  insert into public.games (code, status, result, time_ms, increment_ms, white_ms, black_ms, moves, move_count,
      eval_bar, created_by, white_id, black_id, white_army, black_army, rules, refereed, turn_started_at)
    values (chessplus_private.new_code('games'),
      case when coalesce(p_finished, false) then 'finished' else 'playing' end,
      case when coalesce(p_finished, false) then 'board' else '' end,
      t, bonus, t, t, '[]'::jsonb, 0, false, uid, white_row.user_id, black_row.user_id,
      white_row.white_army, black_row.black_army, mine.rules, coalesce(p_refereed, false), now())
    returning * into g;
  update public.match_queue set game_code = g.code where user_id = theirs.user_id;
  delete from public.match_queue where user_id = uid;
  return chessplus_private.view(g, uid) || jsonb_build_object('seat', case when p_white_user = uid then 'white' else 'black' end);
end $$;

create or replace function public.quick_match_status() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.me();
  mine public.match_queue;
begin
  select * into mine from public.match_queue where user_id = uid for update;
  if not found then
    return jsonb_build_object('gone', true);
  end if;
  if mine.game_code is not null then
    delete from public.match_queue where user_id = uid;
    return jsonb_build_object('code', mine.game_code);
  end if;
  update public.match_queue set seen_at = now() where user_id = uid;
  perform chessplus_private.seen(uid);
  return jsonb_build_object('waiting', true,
    'others', (select count(*) from chessplus_private.quick_candidates(uid, mine.time_ms, mine.increment_ms, mine.rules)));
end $$;

revoke all on all functions in schema chessplus_private from public, anon, authenticated;
revoke all on function
  public.referee_create_game(text, text, jsonb, jsonb, integer, integer, boolean, text),
  public.referee_quick_enter(text, jsonb, jsonb, integer, integer, text),
  public.online_counts(),
  public.get_game(text, integer)
  from public, anon, authenticated;
grant execute on function
  public.referee_create_game(text, text, jsonb, jsonb, integer, integer, boolean, text),
  public.referee_quick_enter(text, jsonb, jsonb, integer, integer, text)
  to service_role;
grant execute on function
  public.online_counts(),
  public.get_game(text, integer)
  to authenticated;

commit;
