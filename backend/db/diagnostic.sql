-- =============================================================================
-- GroupLock / LockIn - Comprehensive Database Diagnostic Script (READ-ONLY)
-- =============================================================================
-- Run this in the Supabase Dashboard SQL Editor before making any changes.
-- It performs a read-only audit of your live database and does NOT modify data.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Table Existence and RLS (Row Level Security) Status
-- -----------------------------------------------------------------------------
with required_tables as (
  select unnest(array[
    'profiles',
    'friends',
    'rooms',
    'room_members',
    'focus_sessions',
    'messages',
    'focus_events',
    'room_rules',
    'user_rules',
    'user_settings',
    'user_focus_settings',
    'room_member_focus',
    'extension_devices'
  ]) as table_name
)
select
  rt.table_name,
  case when t.tablename is not null then 'EXISTS' else 'MISSING' end as table_status,
  case 
    when t.tablename is null then 'N/A'
    when t.rowsecurity then 'ENABLED' 
    else 'DISABLED (WARNING: Vulnerable)' 
  end as rls_status
from required_tables rt
left join pg_tables t 
  on t.schemaname = 'public' and t.tablename = rt.table_name
order by 
  case when t.tablename is null then 0 else 1 end,
  rt.table_name;

-- -----------------------------------------------------------------------------
-- 2. Complete Column Inventory for All 13 Tables
-- -----------------------------------------------------------------------------
with expected_columns as (
  select * from (values
    -- profiles
    ('profiles', 'id'), ('profiles', 'username'), ('profiles', 'full_name'),
    ('profiles', 'avatar_url'), ('profiles', 'school'), ('profiles', 'bio'), ('profiles', 'created_at'),
    -- friends
    ('friends', 'id'), ('friends', 'user_id'), ('friends', 'friend_id'), ('friends', 'status'), ('friends', 'created_at'),
    -- rooms
    ('rooms', 'id'), ('rooms', 'host_id'), ('rooms', 'name'), ('rooms', 'topic'),
    ('rooms', 'visibility'), ('rooms', 'tags'), ('rooms', 'planned_duration_minutes'),
    ('rooms', 'ends_at'), ('rooms', 'created_at'), ('rooms', 'updated_at'),
    -- room_members
    ('room_members', 'room_id'), ('room_members', 'user_id'), ('room_members', 'role'),
    ('room_members', 'joined_at'), ('room_members', 'left_at'),
    -- focus_sessions
    ('focus_sessions', 'id'), ('focus_sessions', 'room_id'), ('focus_sessions', 'user_id'),
    ('focus_sessions', 'started_at'), ('focus_sessions', 'ended_at'), ('focus_sessions', 'goal'),
    ('focus_sessions', 'planned_duration_minutes'), ('focus_sessions', 'actual_focus_minutes'), ('focus_sessions', 'off_task_events'),
    -- messages
    ('messages', 'id'), ('messages', 'room_id'), ('messages', 'user_id'), ('messages', 'content'), ('messages', 'type'), ('messages', 'created_at'),
    -- focus_events
    ('focus_events', 'id'), ('focus_events', 'user_id'), ('focus_events', 'room_id'),
    ('focus_events', 'session_id'), ('focus_events', 'event_type'), ('focus_events', 'domain'), ('focus_events', 'url'), ('focus_events', 'created_at'),
    -- room_rules
    ('room_rules', 'id'), ('room_rules', 'room_id'), ('room_rules', 'allowed_domains'),
    ('room_rules', 'blocked_domains'), ('room_rules', 'strictness'), ('room_rules', 'grace_seconds_before_warning'),
    ('room_rules', 'max_warnings_before_lock'), ('room_rules', 'created_at'), ('room_rules', 'updated_at'),
    -- user_rules
    ('user_rules', 'id'), ('user_rules', 'user_id'), ('user_rules', 'personal_allowed_domains'),
    ('user_rules', 'personal_blocked_domains'), ('user_rules', 'created_at'), ('user_rules', 'updated_at'),
    -- user_settings
    ('user_settings', 'id'), ('user_settings', 'user_id'), ('user_settings', 'email_room_invites'),
    ('user_settings', 'email_focus_recaps'), ('user_settings', 'push_break_reminders'), ('user_settings', 'show_real_name'),
    ('user_settings', 'share_current_room_with_friends'), ('user_settings', 'share_focus_history_with_room'),
    ('user_settings', 'theme'), ('user_settings', 'density'), ('user_settings', 'created_at'), ('user_settings', 'updated_at'),
    -- user_focus_settings
    ('user_focus_settings', 'id'), ('user_focus_settings', 'user_id'), ('user_focus_settings', 'default_strictness'),
    ('user_focus_settings', 'grace_seconds_before_warning'), ('user_focus_settings', 'max_warnings_before_lock'),
    ('user_focus_settings', 'allow_break_requests'), ('user_focus_settings', 'auto_share_off_task_events'),
    ('user_focus_settings', 'created_at'), ('user_focus_settings', 'updated_at'),
    -- room_member_focus
    ('room_member_focus', 'room_id'), ('room_member_focus', 'user_id'), ('room_member_focus', 'focus_state'),
    ('room_member_focus', 'tab_domain'), ('room_member_focus', 'updated_at'),
    -- extension_devices
    ('extension_devices', 'id'), ('extension_devices', 'user_id'), ('extension_devices', 'device_label'),
    ('extension_devices', 'browser_type'), ('extension_devices', 'last_seen_at'), ('extension_devices', 'token_id'), ('extension_devices', 'created_at')
  ) as t(table_name, column_name)
)
select
  ec.table_name,
  ec.column_name,
  case 
    when c.column_name is not null then 'EXISTS' 
    else 'MISSING (ACTION REQUIRED)' 
  end as column_status,
  coalesce(c.data_type, 'N/A') as data_type,
  c.column_default
from expected_columns ec
left join information_schema.columns c
  on c.table_schema = 'public' 
  and c.table_name = ec.table_name 
  and c.column_name = ec.column_name
order by
  case when c.column_name is null then 0 else 1 end,
  ec.table_name,
  ec.column_name;

-- -----------------------------------------------------------------------------
-- 3. RPC Functions & Signature Ambiguity Check
-- -----------------------------------------------------------------------------
select
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as argument_signature,
  pg_get_function_result(p.oid) as return_type,
  case p.prosecdef when true then 'SECURITY DEFINER' else 'INVOKER' end as security_type,
  case 
    when p.proname = 'create_room' and pg_get_function_identity_arguments(p.oid) = 'p_name text, p_topic text' then
      'AMBIGUOUS OVERLOAD (Causes schema cache error - needs drop)'
    when p.proname = 'create_room' and pg_get_function_identity_arguments(p.oid) like 'p_name text, p_topic text, p_tags text[], p_duration_minutes integer%' then
      'CANONICAL RPC (Correct for frontend & backend)'
    else 'OK'
  end as overload_assessment
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('create_room', 'user_can_access_room', 'handle_new_user', 'room_members_updated_at')
order by p.proname, argument_signature;

-- -----------------------------------------------------------------------------
-- 4. Supabase Realtime Publication Membership
-- -----------------------------------------------------------------------------
with required_realtime as (
  select unnest(array['rooms', 'room_members', 'messages', 'room_member_focus']) as table_name
)
select
  rr.table_name,
  case 
    when pt.tablename is not null then 'INCLUDED' 
    else 'NOT IN PUBLICATION (Live sync will not work)' 
  end as realtime_status
from required_realtime rr
left join pg_publication_tables pt 
  on pt.pubname = 'supabase_realtime' 
  and pt.schemaname = 'public' 
  and pt.tablename = rr.table_name
order by rr.table_name;

-- -----------------------------------------------------------------------------
-- 5. Active Triggers Audit
-- -----------------------------------------------------------------------------
select
  trigger_name,
  event_object_table as table_name,
  action_timing,
  event_manipulation as event
from information_schema.triggers
where trigger_name in ('on_auth_user_created', 'room_members_updated_at')
order by trigger_name;
