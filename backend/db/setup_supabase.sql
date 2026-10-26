-- =============================================================================
-- GroupLock / LockIn - Complete, Idempotent Supabase Setup & Repair Script
-- =============================================================================
-- Purpose:
--   Brings any Supabase database (fresh, partially initialized, or existing)
--   into the 100% correct state required by GroupLock.
-- Safety & Idempotency:
--   - Safe to run multiple times (completely idempotent).
--   - Non-destructive: preserves existing users, rooms, chat, rules, and history.
--   - Explicitly checks and repairs missing columns on ALL 13 tables.
--   - Removes the ambiguous create_room(text, text) overload that causes schema cache errors.
--   - Replaces RLS policies cleanly without duplicate policy conflicts.
--   - Safely adds Realtime publication memberships without throwing existing-relation errors.
-- =============================================================================

-- =============================================================================
-- STEP 1: EXTENSIONS
-- =============================================================================
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- =============================================================================
-- STEP 2: TABLES & COMPREHENSIVE COLUMN REPAIRS
-- (Handles brand-new tables AND partially created pre-existing tables)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1 Profiles (1:1 with auth.users)
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  full_name text,
  avatar_url text,
  school text,
  bio text,
  created_at timestamptz not null default now()
);

alter table public.profiles add column if not exists username text;
alter table public.profiles add column if not exists full_name text;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists school text;
alter table public.profiles add column if not exists bio text;
alter table public.profiles add column if not exists created_at timestamptz not null default now();

-- -----------------------------------------------------------------------------
-- 2.2 Friends (Mutual relationships)
-- -----------------------------------------------------------------------------
create table if not exists public.friends (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  friend_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  unique(user_id, friend_id),
  check (user_id != friend_id)
);

alter table public.friends add column if not exists user_id uuid references public.profiles(id) on delete cascade;
alter table public.friends add column if not exists friend_id uuid references public.profiles(id) on delete cascade;
alter table public.friends add column if not exists status text not null default 'pending';
alter table public.friends add column if not exists created_at timestamptz not null default now();

-- -----------------------------------------------------------------------------
-- 2.3 Rooms (Focus rooms)
-- -----------------------------------------------------------------------------
create table if not exists public.rooms (
  id uuid primary key default uuid_generate_v4(),
  host_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  topic text,
  visibility text not null default 'link',
  tags text[] default '{}',
  planned_duration_minutes int default 50,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.rooms add column if not exists host_id uuid references public.profiles(id) on delete cascade;
alter table public.rooms add column if not exists name text not null default 'Study room';
alter table public.rooms add column if not exists topic text;
alter table public.rooms add column if not exists visibility text not null default 'link';
alter table public.rooms add column if not exists tags text[] default '{}';
alter table public.rooms add column if not exists planned_duration_minutes int default 50;
alter table public.rooms add column if not exists ends_at timestamptz;
alter table public.rooms add column if not exists created_at timestamptz not null default now();
alter table public.rooms add column if not exists updated_at timestamptz not null default now();
alter table public.rooms alter column visibility set default 'link';

-- -----------------------------------------------------------------------------
-- 2.4 Room Members (Join/leave tracking with roles)
-- -----------------------------------------------------------------------------
create table if not exists public.room_members (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  primary key (room_id, user_id)
);

alter table public.room_members add column if not exists room_id uuid references public.rooms(id) on delete cascade;
alter table public.room_members add column if not exists user_id uuid references public.profiles(id) on delete cascade;
alter table public.room_members add column if not exists role text not null default 'member';
alter table public.room_members add column if not exists joined_at timestamptz not null default now();
alter table public.room_members add column if not exists left_at timestamptz;

-- -----------------------------------------------------------------------------
-- 2.5 Focus Sessions (Historical session stats)
-- -----------------------------------------------------------------------------
create table if not exists public.focus_sessions (
  id uuid primary key default uuid_generate_v4(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  goal text,
  planned_duration_minutes int,
  actual_focus_minutes int default 0,
  off_task_events int default 0
);

alter table public.focus_sessions add column if not exists room_id uuid references public.rooms(id) on delete cascade;
alter table public.focus_sessions add column if not exists user_id uuid references public.profiles(id) on delete cascade;
alter table public.focus_sessions add column if not exists started_at timestamptz not null default now();
alter table public.focus_sessions add column if not exists ended_at timestamptz;
alter table public.focus_sessions add column if not exists goal text;
alter table public.focus_sessions add column if not exists planned_duration_minutes int;
alter table public.focus_sessions add column if not exists actual_focus_minutes int default 0;
alter table public.focus_sessions add column if not exists off_task_events int default 0;

-- -----------------------------------------------------------------------------
-- 2.6 Messages (Room live chat)
-- -----------------------------------------------------------------------------
create table if not exists public.messages (
  id uuid primary key default uuid_generate_v4(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  type text not null default 'message',
  created_at timestamptz not null default now()
);

alter table public.messages add column if not exists room_id uuid references public.rooms(id) on delete cascade;
alter table public.messages add column if not exists user_id uuid references public.profiles(id) on delete cascade;
alter table public.messages add column if not exists content text;
alter table public.messages add column if not exists type text not null default 'message';
alter table public.messages add column if not exists created_at timestamptz not null default now();

-- -----------------------------------------------------------------------------
-- 2.7 Focus Events (Drift and activity audit events)
-- -----------------------------------------------------------------------------
create table if not exists public.focus_events (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  room_id uuid references public.rooms(id) on delete set null,
  session_id uuid references public.focus_sessions(id) on delete set null,
  event_type text not null,
  domain text,
  url text,
  created_at timestamptz not null default now()
);

alter table public.focus_events add column if not exists user_id uuid references public.profiles(id) on delete cascade;
alter table public.focus_events add column if not exists room_id uuid references public.rooms(id) on delete set null;
alter table public.focus_events add column if not exists session_id uuid references public.focus_sessions(id) on delete set null;
alter table public.focus_events add column if not exists event_type text;
alter table public.focus_events add column if not exists domain text;
alter table public.focus_events add column if not exists url text;
alter table public.focus_events add column if not exists created_at timestamptz not null default now();

-- -----------------------------------------------------------------------------
-- 2.8 Room Rules (Allowed & blocked domains per room)
-- -----------------------------------------------------------------------------
create table if not exists public.room_rules (
  id uuid primary key default uuid_generate_v4(),
  room_id uuid not null references public.rooms(id) on delete cascade unique,
  allowed_domains text[] default '{}',
  blocked_domains text[] default '{}',
  strictness text not null default 'standard',
  grace_seconds_before_warning int default 30,
  max_warnings_before_lock int default 3,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.room_rules add column if not exists room_id uuid references public.rooms(id) on delete cascade;
alter table public.room_rules add column if not exists allowed_domains text[] default '{}';
alter table public.room_rules add column if not exists blocked_domains text[] default '{}';
alter table public.room_rules add column if not exists strictness text not null default 'standard';
alter table public.room_rules add column if not exists grace_seconds_before_warning int default 30;
alter table public.room_rules add column if not exists max_warnings_before_lock int default 3;
alter table public.room_rules add column if not exists created_at timestamptz not null default now();
alter table public.room_rules add column if not exists updated_at timestamptz not null default now();

-- -----------------------------------------------------------------------------
-- 2.9 User Rules (Personal domain overrides)
-- -----------------------------------------------------------------------------
create table if not exists public.user_rules (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade unique,
  personal_allowed_domains text[] default '{}',
  personal_blocked_domains text[] default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_rules add column if not exists user_id uuid references public.profiles(id) on delete cascade;
alter table public.user_rules add column if not exists personal_allowed_domains text[] default '{}';
alter table public.user_rules add column if not exists personal_blocked_domains text[] default '{}';
alter table public.user_rules add column if not exists created_at timestamptz not null default now();
alter table public.user_rules add column if not exists updated_at timestamptz not null default now();

-- -----------------------------------------------------------------------------
-- 2.10 User Settings (Notifications, privacy, appearance)
-- -----------------------------------------------------------------------------
create table if not exists public.user_settings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade unique,
  email_room_invites boolean default true,
  email_focus_recaps boolean default true,
  push_break_reminders boolean default true,
  show_real_name boolean default true,
  share_current_room_with_friends boolean default true,
  share_focus_history_with_room boolean default false,
  theme text not null default 'system',
  density text not null default 'comfortable',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_settings add column if not exists user_id uuid references public.profiles(id) on delete cascade;
alter table public.user_settings add column if not exists email_room_invites boolean default true;
alter table public.user_settings add column if not exists email_focus_recaps boolean default true;
alter table public.user_settings add column if not exists push_break_reminders boolean default true;
alter table public.user_settings add column if not exists show_real_name boolean default true;
alter table public.user_settings add column if not exists share_current_room_with_friends boolean default true;
alter table public.user_settings add column if not exists share_focus_history_with_room boolean default false;
alter table public.user_settings add column if not exists theme text not null default 'system';
alter table public.user_settings add column if not exists density text not null default 'comfortable';
alter table public.user_settings add column if not exists created_at timestamptz not null default now();
alter table public.user_settings add column if not exists updated_at timestamptz not null default now();

-- -----------------------------------------------------------------------------
-- 2.11 User Focus Settings (Focus & accountability preferences)
-- -----------------------------------------------------------------------------
create table if not exists public.user_focus_settings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade unique,
  default_strictness text not null default 'standard',
  grace_seconds_before_warning int default 30,
  max_warnings_before_lock int default 3,
  allow_break_requests boolean default true,
  auto_share_off_task_events boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_focus_settings add column if not exists user_id uuid references public.profiles(id) on delete cascade;
alter table public.user_focus_settings add column if not exists default_strictness text not null default 'standard';
alter table public.user_focus_settings add column if not exists grace_seconds_before_warning int default 30;
alter table public.user_focus_settings add column if not exists max_warnings_before_lock int default 3;
alter table public.user_focus_settings add column if not exists allow_break_requests boolean default true;
alter table public.user_focus_settings add column if not exists auto_share_off_task_events boolean default true;
alter table public.user_focus_settings add column if not exists created_at timestamptz not null default now();
alter table public.user_focus_settings add column if not exists updated_at timestamptz not null default now();

-- -----------------------------------------------------------------------------
-- 2.12 Room Member Focus (Real-time live peer focus status)
-- -----------------------------------------------------------------------------
create table if not exists public.room_member_focus (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  focus_state text not null default 'on-task',
  tab_domain text,
  updated_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

alter table public.room_member_focus add column if not exists room_id uuid references public.rooms(id) on delete cascade;
alter table public.room_member_focus add column if not exists user_id uuid references public.profiles(id) on delete cascade;
alter table public.room_member_focus add column if not exists focus_state text not null default 'on-task';
alter table public.room_member_focus add column if not exists tab_domain text;
alter table public.room_member_focus add column if not exists updated_at timestamptz not null default now();

-- -----------------------------------------------------------------------------
-- 2.13 Extension Devices (Linked browsers)
-- -----------------------------------------------------------------------------
create table if not exists public.extension_devices (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  device_label text,
  browser_type text default 'chrome',
  last_seen_at timestamptz,
  token_id text,
  created_at timestamptz not null default now()
);

alter table public.extension_devices add column if not exists user_id uuid references public.profiles(id) on delete cascade;
alter table public.extension_devices add column if not exists device_label text;
alter table public.extension_devices add column if not exists browser_type text default 'chrome';
alter table public.extension_devices add column if not exists last_seen_at timestamptz;
alter table public.extension_devices add column if not exists token_id text;
alter table public.extension_devices add column if not exists created_at timestamptz not null default now();

-- =============================================================================
-- STEP 3: SAFE CONSTRAINTS REPAIR
-- =============================================================================
do $$
begin
  -- check constraints
  if not exists (select 1 from pg_constraint where conname = 'friends_status_check') then
    alter table public.friends add constraint friends_status_check check (status in ('pending', 'accepted', 'blocked'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'friends_user_id_check') then
    alter table public.friends add constraint friends_user_id_check check (user_id != friend_id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'rooms_visibility_check') then
    alter table public.rooms add constraint rooms_visibility_check check (visibility in ('private', 'friends', 'link'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'room_members_role_check') then
    alter table public.room_members add constraint room_members_role_check check (role in ('host', 'member'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'messages_type_check') then
    alter table public.messages add constraint messages_type_check check (type in ('message', 'system', 'reaction'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'room_rules_strictness_check') then
    alter table public.room_rules add constraint room_rules_strictness_check check (strictness in ('chill', 'standard', 'hardcore'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'user_settings_theme_check') then
    alter table public.user_settings add constraint user_settings_theme_check check (theme in ('light', 'dark', 'system'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'user_settings_density_check') then
    alter table public.user_settings add constraint user_settings_density_check check (density in ('comfortable', 'compact'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'user_focus_settings_strictness_check') then
    alter table public.user_focus_settings add constraint user_focus_settings_strictness_check check (default_strictness in ('chill', 'standard', 'hardcore'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'room_member_focus_state_check') then
    alter table public.room_member_focus add constraint room_member_focus_state_check check (focus_state in ('on-task', 'warning', 'locked', 'approved-break'));
  end if;

  -- unique constraints
  if not exists (select 1 from pg_constraint where conname = 'room_rules_room_id_key') then
    alter table public.room_rules add constraint room_rules_room_id_key unique (room_id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'user_rules_user_id_key') then
    alter table public.user_rules add constraint user_rules_user_id_key unique (user_id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'user_settings_user_id_key') then
    alter table public.user_settings add constraint user_settings_user_id_key unique (user_id);
  end if;
  if not exists (select 1 from pg_constraint where conname = 'user_focus_settings_user_id_key') then
    alter table public.user_focus_settings add constraint user_focus_settings_user_id_key unique (user_id);
  end if;
end $$;

-- =============================================================================
-- STEP 4: INDEXES (Safe with IF NOT EXISTS)
-- =============================================================================
create index if not exists idx_friends_user_id on public.friends(user_id);
create index if not exists idx_friends_friend_id on public.friends(friend_id);
create index if not exists idx_rooms_tags on public.rooms using gin (tags);
create index if not exists idx_rooms_ends_at on public.rooms(ends_at);
create index if not exists idx_room_members_user_id on public.room_members(user_id);
create index if not exists idx_room_members_room_id on public.room_members(room_id);
create index if not exists idx_focus_sessions_room_user on public.focus_sessions(room_id, user_id);
create index if not exists idx_messages_room_id on public.messages(room_id);
create index if not exists idx_focus_events_session_id on public.focus_events(session_id);
create index if not exists idx_extension_devices_user_id on public.extension_devices(user_id);
create index if not exists idx_user_settings_user_id on public.user_settings(user_id);
create index if not exists idx_user_focus_settings_user_id on public.user_focus_settings(user_id);
create index if not exists idx_room_member_focus_room on public.room_member_focus(room_id);

-- =============================================================================
-- STEP 5: FUNCTIONS & TRIGGERS
-- =============================================================================

-- 5.1 Helper function to check room membership without RLS infinite recursion
create or replace function public.user_can_access_room(p_room_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.room_members
    where room_id = p_room_id and user_id = auth.uid()
  );
$$;

-- 5.2 Auto-create profile trigger on auth.users registration
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, profiles.full_name),
    avatar_url = coalesce(excluded.avatar_url, profiles.avatar_url);
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 5.3 Room updated_at sync trigger on membership changes
create or replace function public.room_members_updated_at()
returns trigger as $$
begin
  update public.rooms set updated_at = now() where id = coalesce(new.room_id, old.room_id);
  return coalesce(new, old);
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists room_members_updated_at on public.room_members;
create trigger room_members_updated_at
  after insert or update or delete on public.room_members
  for each row execute function public.room_members_updated_at();

-- 5.4 CRITICAL FIX: create_room RPC Overload Ambiguity Resolution
-- Dropping the legacy 2-argument signature resolves the PostgREST schema cache ambiguity.
-- The canonical 4-argument function below has default parameters for p_tags and p_duration_minutes,
-- so any 2-argument call `{ p_name, p_topic }` is 100% satisfied by it with zero conflict.
drop function if exists public.create_room(text, text);

-- Primary canonical function (matches frontend & backend calls)
create or replace function public.create_room(
  p_name text,
  p_topic text default null,
  p_tags text[] default '{}'::text[],
  p_duration_minutes int default 50
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_room_id uuid;
  v_duration int;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  v_duration := coalesce(nullif(p_duration_minutes, 0), 50);

  insert into public.rooms (host_id, name, topic, visibility, tags, planned_duration_minutes, ends_at)
  values (
    v_user_id,
    coalesce(nullif(trim(p_name), ''), 'Study room'),
    nullif(trim(p_topic), ''),
    'link',
    coalesce(p_tags, '{}'::text[]),
    v_duration,
    now() + make_interval(mins => v_duration)
  )
  returning id into v_room_id;

  insert into public.room_members (room_id, user_id, role)
  values (v_room_id, v_user_id, 'host');

  insert into public.room_rules (room_id, allowed_domains, blocked_domains, strictness)
  values (
    v_room_id,
    array['docs.google.com', 'stackoverflow.com', 'github.com', 'developer.mozilla.org', 'localhost'],
    array['youtube.com', 'reddit.com', 'twitter.com', 'tiktok.com', 'instagram.com', 'x.com'],
    'standard'
  );

  return v_room_id;
end;
$$;

-- Compatibility overload for callers passing duration as first argument
create or replace function public.create_room(
  p_duration_minutes int,
  p_name text,
  p_tags text[] default '{}'::text[],
  p_topic text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
begin
  return public.create_room(
    p_name => p_name,
    p_topic => p_topic,
    p_tags => coalesce(p_tags, '{}'::text[]),
    p_duration_minutes => coalesce(p_duration_minutes, 50)
  );
end;
$$;

-- Execute permissions for RPC functions
grant execute on function public.create_room(text, text, text[], int) to authenticated, anon, service_role;
grant execute on function public.create_room(int, text, text[], text) to authenticated, anon, service_role;
grant execute on function public.user_can_access_room(uuid) to authenticated, anon, service_role;

-- =============================================================================
-- STEP 6: ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================
alter table public.profiles enable row level security;
alter table public.friends enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.focus_sessions enable row level security;
alter table public.messages enable row level security;
alter table public.focus_events enable row level security;
alter table public.room_rules enable row level security;
alter table public.user_rules enable row level security;
alter table public.user_settings enable row level security;
alter table public.user_focus_settings enable row level security;
alter table public.room_member_focus enable row level security;
alter table public.extension_devices enable row level security;

-- 6.1 Profiles Policies
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can view other profiles" on public.profiles;
drop policy if exists "Profiles are viewable by everyone" on public.profiles;
create policy "Profiles are viewable by everyone" on public.profiles for select using (true);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- 6.2 Friends Policies
drop policy if exists "Users can view own friends" on public.friends;
create policy "Users can view own friends" on public.friends for select using (auth.uid() = user_id or auth.uid() = friend_id);

drop policy if exists "Users can insert friend rows" on public.friends;
create policy "Users can insert friend rows" on public.friends for insert with check (auth.uid() = user_id);

drop policy if exists "Users can update own friend rows" on public.friends;
create policy "Users can update own friend rows" on public.friends for update using (auth.uid() = user_id or auth.uid() = friend_id) with check (auth.uid() = user_id or auth.uid() = friend_id);

drop policy if exists "Users can delete own friend rows" on public.friends;
create policy "Users can delete own friend rows" on public.friends for delete using (auth.uid() = user_id or auth.uid() = friend_id);

-- 6.3 Rooms Policies
drop policy if exists "Users can view rooms they are in" on public.rooms;
drop policy if exists "Users can view link-visible rooms" on public.rooms;
drop policy if exists "Users can view accessible rooms" on public.rooms;
create policy "Users can view accessible rooms" on public.rooms for select using (
  visibility = 'link'
  or exists (select 1 from public.room_members rm where rm.room_id = rooms.id and rm.user_id = auth.uid())
  or (visibility = 'friends' and exists (
    select 1 from public.friends f 
    where ((f.user_id = auth.uid() and f.friend_id = rooms.host_id) or (f.friend_id = auth.uid() and f.user_id = rooms.host_id))
      and f.status = 'accepted'
  ))
);

drop policy if exists "Users can create rooms" on public.rooms;
create policy "Users can create rooms" on public.rooms for insert with check (auth.uid() = host_id);

drop policy if exists "Hosts can update own rooms" on public.rooms;
create policy "Hosts can update own rooms" on public.rooms for update using (auth.uid() = host_id) with check (auth.uid() = host_id);

drop policy if exists "Hosts can delete own rooms" on public.rooms;
create policy "Hosts can delete own rooms" on public.rooms for delete using (auth.uid() = host_id);

-- 6.4 Room Members Policies (Safe with user_can_access_room to prevent recursion)
drop policy if exists "Users can view room members of accessible rooms" on public.room_members;
create policy "Users can view room members of accessible rooms" on public.room_members
  for select using (auth.uid() = user_id or user_can_access_room(room_id));

drop policy if exists "Users can join rooms" on public.room_members;
create policy "Users can join rooms" on public.room_members for insert with check (auth.uid() = user_id);

drop policy if exists "Users can update own membership" on public.room_members;
create policy "Users can update own membership" on public.room_members for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users can leave rooms" on public.room_members;
create policy "Users can leave rooms" on public.room_members for delete using (auth.uid() = user_id);

-- 6.5 Focus Sessions Policies
drop policy if exists "Users can view focus sessions in accessible rooms" on public.focus_sessions;
create policy "Users can view focus sessions in accessible rooms" on public.focus_sessions for select using (
  exists (select 1 from public.room_members rm where rm.room_id = focus_sessions.room_id and rm.user_id = auth.uid())
);

drop policy if exists "Users can insert own focus sessions" on public.focus_sessions;
create policy "Users can insert own focus sessions" on public.focus_sessions for insert with check (auth.uid() = user_id);

drop policy if exists "Users can update own focus sessions" on public.focus_sessions;
create policy "Users can update own focus sessions" on public.focus_sessions for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 6.6 Messages Policies
drop policy if exists "Users can view messages in joined rooms" on public.messages;
create policy "Users can view messages in joined rooms" on public.messages for select using (
  exists (select 1 from public.room_members rm where rm.room_id = messages.room_id and rm.user_id = auth.uid())
);

drop policy if exists "Users can send messages in joined rooms" on public.messages;
create policy "Users can send messages in joined rooms" on public.messages for insert with check (
  auth.uid() = user_id and exists (select 1 from public.room_members rm where rm.room_id = messages.room_id and rm.user_id = auth.uid())
);

-- 6.7 Focus Events Policies
drop policy if exists "Users can view own focus events" on public.focus_events;
create policy "Users can view own focus events" on public.focus_events for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own focus events" on public.focus_events;
create policy "Users can insert own focus events" on public.focus_events for insert with check (auth.uid() = user_id);

-- 6.8 Room Rules Policies
drop policy if exists "Users can view room rules for joined rooms" on public.room_rules;
create policy "Users can view room rules for joined rooms" on public.room_rules for select using (
  exists (select 1 from public.room_members rm where rm.room_id = room_rules.room_id and rm.user_id = auth.uid())
);

drop policy if exists "Hosts can manage room rules" on public.room_rules;
create policy "Hosts can manage room rules" on public.room_rules for all using (
  exists (select 1 from public.rooms r where r.id = room_rules.room_id and r.host_id = auth.uid())
) with check (
  exists (select 1 from public.rooms r where r.id = room_rules.room_id and r.host_id = auth.uid())
);

-- 6.9 User Rules Policies
drop policy if exists "Users can manage own user rules" on public.user_rules;
create policy "Users can manage own user rules" on public.user_rules for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 6.10 User Settings Policies
drop policy if exists "Users can manage own user settings" on public.user_settings;
create policy "Users can manage own user settings" on public.user_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 6.11 User Focus Settings Policies
drop policy if exists "Users can manage own user focus settings" on public.user_focus_settings;
create policy "Users can manage own user focus settings" on public.user_focus_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 6.12 Room Member Focus Policies (Real-time live peer focus status)
drop policy if exists "Room members can view focus rows in their rooms" on public.room_member_focus;
create policy "Room members can view focus rows in their rooms"
  on public.room_member_focus for select
  using (
    exists (
      select 1 from public.room_members rm
      where rm.room_id = room_member_focus.room_id
        and rm.user_id = auth.uid()
        and rm.left_at is null
    )
  );

drop policy if exists "Members can insert own focus row" on public.room_member_focus;
create policy "Members can insert own focus row"
  on public.room_member_focus for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.room_members rm
      where rm.room_id = room_member_focus.room_id
        and rm.user_id = auth.uid()
        and rm.left_at is null
    )
  );

drop policy if exists "Members can update own focus row" on public.room_member_focus;
create policy "Members can update own focus row"
  on public.room_member_focus for update
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.room_members rm
      where rm.room_id = room_member_focus.room_id
        and rm.user_id = auth.uid()
        and rm.left_at is null
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.room_members rm
      where rm.room_id = room_member_focus.room_id
        and rm.user_id = auth.uid()
        and rm.left_at is null
    )
  );

-- 6.13 Extension Devices Policies
drop policy if exists "Users can manage own extension devices" on public.extension_devices;
create policy "Users can manage own extension devices" on public.extension_devices for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- =============================================================================
-- STEP 7: GENERAL TABLE PERMISSIONS
-- =============================================================================
grant usage on schema public to authenticated, anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on all tables in schema public to anon;
grant all on all tables in schema public to service_role;

-- =============================================================================
-- STEP 8: REALTIME PUBLICATIONS (Safe and Idempotent)
-- =============================================================================
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'rooms'
  ) then
    alter publication supabase_realtime add table public.rooms;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'room_members'
  ) then
    alter publication supabase_realtime add table public.room_members;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'room_member_focus'
  ) then
    alter publication supabase_realtime add table public.room_member_focus;
  end if;
end $$;

-- =============================================================================
-- STEP 9: RELOAD POSTGREST SCHEMA CACHE
-- =============================================================================
notify pgrst, 'reload schema';
