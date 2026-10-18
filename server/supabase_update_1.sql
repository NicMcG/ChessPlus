-- Chess Plus online update 1: chat, draw offers and rematches.
-- Run once in the Supabase SQL Editor (after supabase_setup.sql).

alter table public.games add column if not exists chat jsonb not null default '[]'::jsonb;
alter table public.games add column if not exists draw_offer text not null default '';
alter table public.games add column if not exists rematch text not null default '';

-- Add one chat message to a game in one step, so two messages sent at the same
-- moment can never overwrite each other. Messages are cut to 200 characters.
create or replace function public.post_chat(game_code text, sender text, message text)
returns setof public.games
language sql
as $$
  update public.games
     set chat = chat || jsonb_build_array(jsonb_build_object('from', sender, 'text', left(message, 200)))
   where code = game_code
  returning *;
$$;

grant execute on function public.post_chat(text, text, text) to anon;
