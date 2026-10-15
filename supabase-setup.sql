-- Stillday: run once in Supabase Dashboard → SQL Editor.
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 500),
  status text not null default 'catch' check (status in ('catch','today','horizon','done','released')),
  estimated_minutes integer check (estimated_minutes is null or estimated_minutes between 1 and 1440),
  energy text check (energy is null or energy in ('gentle','steady','deep')),
  context text,
  area text,
  importance text check (importance is null or importance in ('essential','useful','optional')),
  due_at timestamptz,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists tasks_user_status_sort_idx on public.tasks(user_id,status,sort_order,created_at);
create index if not exists tasks_user_due_at_idx on public.tasks(user_id,due_at) where due_at is not null;
alter table public.tasks enable row level security;
drop policy if exists "Users can read their own tasks" on public.tasks;
drop policy if exists "Users can create their own tasks" on public.tasks;
drop policy if exists "Users can update their own tasks" on public.tasks;
drop policy if exists "Users can delete their own tasks" on public.tasks;
create policy "Users can read their own tasks" on public.tasks for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users can create their own tasks" on public.tasks for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users can update their own tasks" on public.tasks for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users can delete their own tasks" on public.tasks for delete to authenticated using ((select auth.uid()) = user_id);
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.tasks to authenticated;
create or replace function public.set_task_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists set_tasks_updated_at on public.tasks;
create trigger set_tasks_updated_at before update on public.tasks for each row execute function public.set_task_updated_at();
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'tasks') then
    execute 'alter publication supabase_realtime add table public.tasks';
  end if;
end $$;


-- Per-account presentation settings, kept separate from the task list.
create table if not exists public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  theme text not null default 'stillday' check (theme in ('stillday','moss','blossom','ocean')),
  appearance text not null default 'system' check (appearance in ('system','light','dark')),
  section_order text[] not null default array['focus','tasks','radar'],
  hidden_sections text[] not null default array[]::text[],
  categories text[] not null default array['Work','Home','Health','Someday']::text[],
  updated_at timestamptz not null default now(),
  radar_minutes integer not null default 15 check (radar_minutes in (5,15,30,60)),
  radar_energy text not null default 'steady' check (radar_energy in ('gentle','steady','deep')),
  radar_context text not null default 'any'
);
alter table public.user_preferences add column if not exists categories text[] not null default array['Work','Home','Health','Someday']::text[];
alter table public.user_preferences add column if not exists radar_minutes integer not null default 15 check (radar_minutes in (5,15,30,60));
alter table public.user_preferences add column if not exists radar_energy text not null default 'steady' check (radar_energy in ('gentle','steady','deep'));
alter table public.user_preferences add column if not exists radar_context text not null default 'any';

-- Preserve any life areas already assigned to tasks before categories became editable.
update public.user_preferences p
set categories = p.categories || coalesce((
  select array_agg(distinct t.area)
  from public.tasks t
  where t.user_id = p.user_id
    and t.area is not null and btrim(t.area) <> ''
    and not (t.area = any(p.categories))
), array[]::text[]);
alter table public.user_preferences enable row level security;
drop policy if exists "Users can read their own preferences" on public.user_preferences;
drop policy if exists "Users can create their own preferences" on public.user_preferences;
drop policy if exists "Users can update their own preferences" on public.user_preferences;
create policy "Users can read their own preferences" on public.user_preferences for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users can create their own preferences" on public.user_preferences for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users can update their own preferences" on public.user_preferences for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
grant select, insert, update on public.user_preferences to authenticated;
drop trigger if exists set_user_preferences_updated_at on public.user_preferences;
create trigger set_user_preferences_updated_at before update on public.user_preferences for each row execute function public.set_task_updated_at();
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'user_preferences') then
    execute 'alter publication supabase_realtime add table public.user_preferences';
  end if;
end $$;
