-- =============================================================================
-- GroupLock / LockIn - Post-Setup Verification Script (READ-ONLY)
-- =============================================================================
-- Run this in the Supabase Dashboard SQL Editor after running setup_supabase.sql
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Tables & RLS Status Verification
-- -----------------------------------------------------------------------------
with expected_tables as (
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
  '1. Tables & RLS' as check_category,
  et.table_name as object_name,
  case 
    when t.tablename is null then '❌ FAIL: Table missing'
    when not t.rowsecurity then '⚠️ WARNING: RLS not enabled'
    else '✅ PASS: Table exists with RLS enabled'
  end as status
from expected_tables et
left join pg_tables t on t.schemaname = 'public' and t.tablename = et.table_name
order by et.table_name;

-- -----------------------------------------------------------------------------
-- 2. Critical Columns Verification
-- -----------------------------------------------------------------------------
with expected_cols as (
  select * from (values
    ('rooms', 'tags', 'ARRAY'),
    ('rooms', 'planned_duration_minutes', 'integer'),
    ('rooms', 'ends_at', 'timestamp with time zone'),
    ('rooms', 'visibility', 'text'),
    ('room_member_focus', 'focus_state', 'text'),
    ('room_member_focus', 'tab_domain', 'text'),
    ('user_settings', 'theme', 'text'),
    ('user_settings', 'density', 'text'),
    ('user_focus_settings', 'default_strictness', 'text'),
    ('room_rules', 'allowed_domains', 'ARRAY'),
    ('room_rules', 'blocked_domains', 'ARRAY')
  ) as t(table_name, column_name, expected_type)
)
select 
  '2. Critical Columns' as check_category,
  ec.table_name || '.' || ec.column_name as object_name,
  case 
    when c.column_name is null then '❌ FAIL: Column missing'
    else '✅ PASS: Exists (' || c.data_type || ')'
  end as status
from expected_cols ec
left join information_schema.columns c
  on c.table_schema = 'public' 
  and c.table_name = ec.table_name 
  and c.column_name = ec.column_name
order by ec.table_name, ec.column_name;

-- -----------------------------------------------------------------------------
-- 3. Functions & Overload Verification
-- -----------------------------------------------------------------------------
with expected_funcs as (
  select * from (values
    ('create_room', 'p_name text, p_topic text, p_tags text[], p_duration_minutes integer'),
    ('user_can_access_room', 'p_room_id uuid'),
    ('handle_new_user', ''),
    ('room_members_updated_at', '')
  ) as t(function_name, expected_arg_prefix)
),
ambiguous_check as (
  select count(*) as cnt
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' 
    and p.proname = 'create_room' 
    and pg_get_function_identity_arguments(p.oid) = 'p_name text, p_topic text'
)
select 
  '3. Functions' as check_category,
  ef.function_name as object_name,
  case 
    when count(p.oid) = 0 then '❌ FAIL: Function missing'
    when ef.function_name = 'create_room' and (select cnt from ambiguous_check) > 0 then
      '⚠️ WARNING: Ambiguous create_room(text, text) still present'
    else '✅ PASS: Function properly registered'
  end as status
from expected_funcs ef
left join pg_proc p on p.proname = ef.function_name
join pg_namespace n on n.oid = p.pronamespace and n.nspname = 'public'
group by ef.function_name;

-- -----------------------------------------------------------------------------
-- 4. Realtime Publication Verification
-- -----------------------------------------------------------------------------
with expected_realtime as (
  select unnest(array['rooms', 'room_members', 'messages', 'room_member_focus']) as table_name
)
select 
  '4. Realtime Sync' as check_category,
  er.table_name as object_name,
  case 
    when pt.tablename is not null then '✅ PASS: Active in publication'
    else '❌ FAIL: Not in publication'
  end as status
from expected_realtime er
left join pg_publication_tables pt 
  on pt.pubname = 'supabase_realtime' 
  and pt.schemaname = 'public' 
  and pt.tablename = er.table_name
order by er.table_name;

-- -----------------------------------------------------------------------------
-- 5. Overall Database Health Verdict
-- -----------------------------------------------------------------------------
with missing_tables as (
  select count(*) as cnt from (
    select unnest(array[
      'profiles','friends','rooms','room_members','focus_sessions',
      'messages','focus_events','room_rules','user_rules',
      'user_settings','user_focus_settings','room_member_focus','extension_devices'
    ]) as t
  ) req
  where not exists (select 1 from pg_tables where schemaname = 'public' and tablename = req.t)
),
missing_tags as (
  select case when exists (
    select 1 from information_schema.columns 
    where table_schema = 'public' and table_name = 'rooms' and column_name = 'tags'
  ) then 0 else 1 end as cnt
),
missing_rpc as (
  select case when exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'create_room'
  ) then 0 else 1 end as cnt
),
ambiguous_rpc as (
  select count(*) as cnt
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' 
    and p.proname = 'create_room' 
    and pg_get_function_identity_arguments(p.oid) = 'p_name text, p_topic text'
)
select
  case 
    when mt.cnt = 0 and mtag.cnt = 0 and mrpc.cnt = 0 and arpc.cnt = 0 then
      '🎉 SUCCESS: All 13 tables, critical columns (rooms.tags), clean RPC signatures, and Realtime sync are 100% ready!'
    when arpc.cnt > 0 then
      '⚠️ ATTENTION: Ambiguous create_room(text, text) is still present. Run setup_supabase.sql to resolve.'
    else
      '⚠️ ATTENTION: Setup incomplete. Missing tables: ' || mt.cnt || ', Missing tags column: ' || mtag.cnt || ', Missing create_room: ' || mrpc.cnt
  end as final_verdict
from missing_tables mt, missing_tags mtag, missing_rpc mrpc, ambiguous_rpc arpc;
