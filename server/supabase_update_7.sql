-- Chess Plus online update 7: reports are kept for 90 days (Mac, Oct 2026).
--
-- Run once in the SQL Editor, after updates 3 to 6. Nothing in the game needs
-- uploading first.
--
-- A reported game's chat and moves (the `reports` table) are deleted 90 days
-- after the report, as the privacy notice in Settings says. The clean-up runs
-- whenever a game is created, joined or paired, like the clearing of old games.

-- All or nothing: if any line fails, nothing changes.
begin;

-- Clear old games and old reports away so the database never fills up.
create or replace function chessplus_private.cleanup() returns void
language sql volatile set search_path = '' as $$
  delete from public.games where code in (
    select code from public.games
     where (status = 'waiting' and updated_at < now() - interval '1 day')
        or (status <> 'waiting' and updated_at < now() - interval '30 days')
     limit 200);
  delete from public.reports where created_at < now() - interval '90 days';
$$;

commit;
