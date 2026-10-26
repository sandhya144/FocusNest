-- =============================================================================
-- GroupLock / LockIn - Database Seed Data
-- =============================================================================

-- Note: In Supabase, users usually register via auth.users.
-- This seed script provides sample demo rooms and rules for development.

do $$
declare
  v_demo_user_id uuid := '00000000-0000-0000-0000-000000000001'::uuid;
  v_alex_user_id uuid := '00000000-0000-0000-0000-000000000002'::uuid;
  v_sarah_user_id uuid := '00000000-0000-0000-0000-000000000003'::uuid;

  v_room_cs_id uuid := '11111111-1111-1111-1111-111111111111'::uuid;
  v_room_deep_id uuid := '22222222-2222-2222-2222-222222222222'::uuid;
  v_room_leetcode_id uuid := '33333333-3333-3333-3333-333333333333'::uuid;
begin

  -- ---------------------------------------------------------------------------
  -- 1. Profiles (Insert sample dummy profiles if auth.users rows exist or directly)
  -- ---------------------------------------------------------------------------
  -- Profiles link to auth.users. When testing locally with mock users:
  -- (If running against real Supabase Auth, profiles will be auto-created by trigger)

  -- ---------------------------------------------------------------------------
  -- 2. Sample Focus Rooms
  -- ---------------------------------------------------------------------------
  -- Room 1: CS 101 Study Group
  insert into public.rooms (id, host_id, name, topic, visibility, tags, planned_duration_minutes, ends_at)
  select
    v_room_cs_id,
    p.id,
    'CS 101 Finals Prep',
    'Data Structures & Algorithms review session',
    'link',
    array['cs', 'dsa', 'finals'],
    60,
    now() + interval '60 minutes'
  from public.profiles p limit 1
  on conflict (id) do nothing;

  -- Room 2: Deep Work Sprint
  insert into public.rooms (id, host_id, name, topic, visibility, tags, planned_duration_minutes, ends_at)
  select
    v_room_deep_id,
    p.id,
    'Deep Work Sprint (Pomodoro)',
    'Silent 50-minute deep work block — cameras optional, no chatting',
    'link',
    array['deepwork', 'pomodoro', 'silent'],
    50,
    now() + interval '50 minutes'
  from public.profiles p limit 1
  on conflict (id) do nothing;

  -- Room 3: LeetCode Grinding
  insert into public.rooms (id, host_id, name, topic, visibility, tags, planned_duration_minutes, ends_at)
  select
    v_room_leetcode_id,
    p.id,
    'Daily LeetCode Challenge',
    'Tackling today''s medium question together and discussing solutions',
    'link',
    array['coding', 'leetcode', 'interviews'],
    45,
    now() + interval '45 minutes'
  from public.profiles p limit 1
  on conflict (id) do nothing;

  -- ---------------------------------------------------------------------------
  -- 3. Room Rules
  -- ---------------------------------------------------------------------------
  insert into public.room_rules (room_id, allowed_domains, blocked_domains, strictness, grace_seconds_before_warning, max_warnings_before_lock)
  values
    (
      v_room_cs_id,
      array['docs.google.com', 'stackoverflow.com', 'github.com', 'developer.mozilla.org', 'mit.edu'],
      array['youtube.com', 'reddit.com', 'twitter.com', 'x.com', 'tiktok.com', 'instagram.com', 'facebook.com', 'netflix.com'],
      'standard',
      30,
      3
    ),
    (
      v_room_deep_id,
      array['github.com', 'notion.so', 'figma.com', 'linear.app'],
      array['youtube.com', 'reddit.com', 'twitter.com', 'x.com', 'tiktok.com', 'instagram.com', 'facebook.com', 'discord.com'],
      'hardcore',
      15,
      2
    ),
    (
      v_room_leetcode_id,
      array['leetcode.com', 'neetcode.io', 'github.com', 'python.org', 'cppreference.com'],
      array['youtube.com', 'reddit.com', 'twitter.com', 'x.com', 'tiktok.com', 'instagram.com', 'facebook.com'],
      'standard',
      30,
      3
    )
  on conflict (room_id) do update set
    allowed_domains = excluded.allowed_domains,
    blocked_domains = excluded.blocked_domains,
    strictness = excluded.strictness;

end $$;

