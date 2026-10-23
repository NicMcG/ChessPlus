-- Chess Plus online update 5: Quick match and reports (Oct 2026).
--
-- Run once in the SQL Editor AFTER the referee is uploaded with Quick match
-- (tools/deploy_referee.sh), after updates 3 and 4.
--
-- Quick match: a player picks an army and a time (or Any) and waits in a queue;
-- the referee pairs them with someone whose time fits, checking both armies
-- first. Sides are random; Any with Any plays 10 minutes each.
--
-- Reports: a player can report their opponent from the chat. The report keeps
-- the game's chat and moves. Read them in the Table Editor ("reports"); to
-- block a device, copy its reported_id into the "banned" table.

-- All or nothing: if any line fails, nothing changes.
begin;

-- One row per player waiting for a quick match.
create table if not exists public.match_queue (
  user_id     text primary key,
  white_army  jsonb not null,
  black_army  jsonb not null,
  time_ms     integer not null,      -- -1 = Any
  rules       text not null,
  game_code   text,                  -- set once paired
  seen_at     timestamptz not null default now(),
  entered_at  timestamptz not null default now()
);
alter table public.match_queue enable row level security;
revoke all on public.match_queue from anon, authenticated;

create table if not exists public.reports (
  id           bigint generated always as identity primary key,
  created_at   timestamptz not null default now(),
  code         text not null,
  reporter_id  text not null,
  reported_id  text not null,
  reason       text not null default '',
  chat         jsonb not null default '[]'::jsonb,
  moves        jsonb not null default '[]'::jsonb,
  unique (code, reporter_id)
);
alter table public.reports enable row level security;
revoke all on public.reports from anon, authenticated;

-- Waiting players whose time fits `p_time_ms` and who were here in the last
-- 20 seconds (they check every few seconds while waiting), oldest first.
create or replace function chessplus_private.quick_candidates(uid text, p_time_ms integer, p_rules text)
returns setof public.match_queue
language sql stable set search_path = '' as $$
  select * from public.match_queue q
   where q.user_id <> uid and q.game_code is null and q.rules = p_rules
     and q.seen_at > now() - interval '20 seconds'
     and (q.time_ms = p_time_ms or q.time_ms = -1 or p_time_ms = -1)
   order by q.entered_at
   limit 5;
$$;

-- The referee puts a player in the queue (armies already checked) and gets
-- back {"code"} if they've been paired meanwhile, else {"candidates": [...]}:
-- waiting players to try pairing with.
create or replace function public.referee_quick_enter(p_user text, p_white_army jsonb, p_black_army jsonb,
    p_time_ms integer, p_rules text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.player(p_user);
  mine public.match_queue;
begin
  if p_time_ms is null or p_time_ms not in (-1, 0, 180000, 300000, 600000, 900000, 1800000) then
    raise exception 'That time limit isn''t one of the choices.';
  end if;
  if not chessplus_private.army_ok(p_white_army) or not chessplus_private.army_ok(p_black_army) then
    raise exception 'That army can''t be used online.';
  end if;
  delete from public.match_queue where seen_at < now() - interval '1 hour';
  select * into mine from public.match_queue where user_id = uid;
  if found and mine.game_code is not null then
    delete from public.match_queue where user_id = uid;
    return jsonb_build_object('code', mine.game_code);
  end if;
  insert into public.match_queue (user_id, white_army, black_army, time_ms, rules)
    values (uid, p_white_army, p_black_army, p_time_ms, p_rules)
    on conflict (user_id) do update set white_army = excluded.white_army, black_army = excluded.black_army,
      time_ms = excluded.time_ms, rules = excluded.rules, game_code = null, seen_at = now();
  return jsonb_build_object('candidates', coalesce((
    select jsonb_agg(jsonb_build_object('user_id', c.user_id, 'white_army', c.white_army,
             'black_army', c.black_army, 'time_ms', c.time_ms))
      from chessplus_private.quick_candidates(uid, p_time_ms, p_rules) c), '[]'::jsonb));
end $$;

-- Pair the caller with `p_other` (the referee has checked the armies, picked
-- the sides and worked out whether the game is over at once). Null if the
-- other player has gone or been paired meanwhile.
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
  g public.games;
begin
  -- One pairing at a time, so two players can't both take the same opponent.
  perform pg_advisory_xact_lock(4242);
  select * into mine from public.match_queue where user_id = uid and game_code is null;
  select * into theirs from public.match_queue
   where user_id = p_other and game_code is null and seen_at > now() - interval '20 seconds';
  if mine.user_id is null or theirs.user_id is null or mine.rules <> theirs.rules
     or not (mine.time_ms = theirs.time_ms or mine.time_ms = -1 or theirs.time_ms = -1)
     or exists (select 1 from public.banned b where b.user_id = p_other) then
    return null;
  end if;
  t := case when mine.time_ms >= 0 then mine.time_ms when theirs.time_ms >= 0 then theirs.time_ms else 600000 end;
  if p_white_user = uid then
    white_row := mine; black_row := theirs;
  else
    white_row := theirs; black_row := mine;
  end if;
  insert into public.games (code, status, result, time_ms, white_ms, black_ms, moves, move_count,
      eval_bar, created_by, white_id, black_id, white_army, black_army, rules, refereed, turn_started_at)
    values (chessplus_private.new_code('games'),
      case when coalesce(p_finished, false) then 'finished' else 'playing' end,
      case when coalesce(p_finished, false) then 'board' else '' end,
      t, t, t, '[]'::jsonb, 0, false, uid, white_row.user_id, black_row.user_id,
      white_row.white_army, black_row.black_army, mine.rules, coalesce(p_refereed, false), now())
    returning * into g;
  update public.match_queue set game_code = g.code where user_id = theirs.user_id;
  delete from public.match_queue where user_id = uid;
  return chessplus_private.view(g, uid) || jsonb_build_object('seat', case when p_white_user = uid then 'white' else 'black' end);
end $$;

-- While waiting: {"code"} once paired (and out of the queue), else
-- {"waiting": true, "others": n} (n others whose time fits: then ask the
-- referee to pair again), or {"gone": true} if not in the queue.
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
  return jsonb_build_object('waiting', true,
    'others', (select count(*) from chessplus_private.quick_candidates(uid, mine.time_ms, mine.rules)));
end $$;

-- Stop waiting. {"code"} if the player was paired just before (the game is on).
create or replace function public.leave_quick_match() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  uid text := chessplus_private.me();
  paired text;
begin
  delete from public.match_queue where user_id = uid returning game_code into paired;
  if paired is not null then
    return jsonb_build_object('code', paired);
  end if;
  return jsonb_build_object('left', true);
end $$;

-- Report the opponent in a game: keeps the chat and moves for Mac to read.
create or replace function public.report_player(p_code text, p_seat text, p_reason text default '') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  g public.games := chessplus_private.my_game(p_code, p_seat);
  uid text := chessplus_private.me();
  other text := case when p_seat = 'white' then g.black_id else g.white_id end;
begin
  if coalesce(other, '') = '' or other = uid then
    raise exception 'There''s no opponent to report.';
  end if;
  if exists (select 1 from public.reports r where r.code = g.code and r.reporter_id = uid) then
    raise exception 'You''ve already reported this game.';
  end if;
  if (select count(*) from public.reports r where r.reporter_id = uid and r.created_at > now() - interval '1 day') >= 20 then
    raise exception 'Too many reports today.';
  end if;
  insert into public.reports (code, reporter_id, reported_id, reason, chat, moves)
    values (g.code, uid, other, left(coalesce(p_reason, ''), 500), g.chat, g.moves);
  return jsonb_build_object('reported', true);
end $$;

revoke all on all functions in schema chessplus_private from public, anon, authenticated;
revoke all on function
  public.referee_quick_enter(text, jsonb, jsonb, integer, text),
  public.referee_quick_pair(text, text, text, boolean, boolean),
  public.quick_match_status(),
  public.leave_quick_match(),
  public.report_player(text, text, text)
  from public, anon, authenticated;
grant execute on function
  public.referee_quick_enter(text, jsonb, jsonb, integer, text),
  public.referee_quick_pair(text, text, text, boolean, boolean)
  to service_role;
grant execute on function
  public.quick_match_status(),
  public.leave_quick_match(),
  public.report_player(text, text, text)
  to authenticated;

commit;
