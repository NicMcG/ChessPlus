-- Chess Plus online update 4: the referee (Oct 2026).
--
-- Run once in the SQL Editor AFTER the referee is uploaded
-- (tools/deploy_referee.sh) and after update 3.
--
-- Creating a game, joining one and playing a move now go only through the
-- referee (server/supabase/functions/referee), which checks the army or the
-- move with the game's own rules before calling the functions below. Only the
-- referee may call them (it uses the server's own key); the app's direct
-- versions from update 3 are removed. Copies of the game from before this
-- update can't create, join or move online until they update themselves.

-- All or nothing: if any line fails, nothing changes.
begin;

-- Which rule set (RuleSet.version()) the game is judged by, and whether the
-- referee can judge it (false when Plusfish doesn't know a rule the armies
-- use; then only the turn order is checked).
alter table public.games add column if not exists rules text not null default '';
alter table public.games add column if not exists refereed boolean not null default true;

-- The player the referee acts for, or an error if they're banned.
create or replace function chessplus_private.player(p_user text) returns text
language plpgsql stable set search_path = '' as $$
begin
  if p_user is null or p_user = '' then
    raise exception 'Please sign in again.';
  end if;
  if exists (select 1 from public.banned b where b.user_id = p_user) then
    raise exception 'This device can''t play online.';
  end if;
  return p_user;
end $$;

-- A game locked for changing, after checking `seat` is `uid`'s.
create or replace function chessplus_private.seat_game(uid text, p_code text, p_seat text) returns public.games
language plpgsql volatile set search_path = '' as $$
declare
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

-- Create a game (the referee has checked the army and picked a Random side).
create or replace function public.referee_create_game(p_user text, p_seat text, p_white_army jsonb,
    p_black_army jsonb, p_time_ms integer, p_eval_bar boolean, p_rules text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.player(p_user);
  g public.games;
begin
  if p_seat is null or p_seat not in ('white', 'black') then
    raise exception 'Choose White, Black or Random.';
  end if;
  if p_time_ms is null or p_time_ms not in (0, 180000, 300000, 600000, 900000, 1800000) then
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
  insert into public.games (code, status, result, time_ms, white_ms, black_ms, moves, move_count,
      eval_bar, created_by, white_id, black_id, white_army, black_army, rules)
    values (chessplus_private.new_code('games'), 'waiting', '', p_time_ms, p_time_ms, p_time_ms,
      '[]'::jsonb, 0, coalesce(p_eval_bar, false), uid,
      case when p_seat = 'white' then uid end, case when p_seat = 'black' then uid end,
      case when p_seat = 'white' then p_white_army end, case when p_seat = 'black' then p_black_army end,
      coalesce(p_rules, ''))
    returning * into g;
  return chessplus_private.view(g, uid);
end $$;

-- Join a waiting game (the referee has checked the army, and whether the game
-- is over before it starts: p_finished, King exposed).
create or replace function public.referee_join_game(p_user text, p_code text, p_white_army jsonb,
    p_black_army jsonb, p_finished boolean, p_refereed boolean) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.player(p_user);
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
      refereed = coalesce(p_refereed, false),
      status = case when coalesce(p_finished, false) then 'finished' else 'playing' end,
      result = case when coalesce(p_finished, false) then 'board' else result end,
      turn_started_at = now()
    where code = c returning * into g;
  return chessplus_private.view(g, uid) || jsonb_build_object('seat', seat);
end $$;

-- Play a move the referee has judged (p_finished = the game ended on the
-- board; p_refereed = false once the referee can no longer judge this game).
-- Same checks and clock as update 3's play_move.
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

-- The app's own versions are gone: only the referee creates, joins and moves.
drop function if exists public.create_game(text, jsonb, jsonb, integer, boolean);
drop function if exists public.join_game(text, jsonb, jsonb);
drop function if exists public.play_move(text, text, text, integer, integer, boolean);

-- Only the referee (the server's own key) may call these.
revoke all on all functions in schema chessplus_private from public, anon, authenticated;
revoke all on function
  public.referee_create_game(text, text, jsonb, jsonb, integer, boolean, text),
  public.referee_join_game(text, text, jsonb, jsonb, boolean, boolean),
  public.referee_play_move(text, text, text, text, integer, integer, boolean, boolean)
  from public, anon, authenticated;
grant execute on function
  public.referee_create_game(text, text, jsonb, jsonb, integer, boolean, text),
  public.referee_join_game(text, text, jsonb, jsonb, boolean, boolean),
  public.referee_play_move(text, text, text, text, integer, integer, boolean, boolean)
  to service_role;

commit;
