# GroupLock Database (PostgreSQL + Supabase)

This directory contains the complete database layer for the GroupLock / LockIn application.

## Directory Structure

```
backend/db/
├── setup_supabase.sql   # Idempotent master setup & repair script (Recommended for Dashboard)
├── diagnostic.sql       # Read-only audit script to check live DB status
├── verify_setup.sql     # Post-setup validation script
├── schema.sql           # Unified master schema
├── seed.sql             # Sample data for development and testing (optional)
├── types.ts             # TypeScript types for all database tables and queries
├── client.ts            # Supabase database client utilities
├── config.toml          # Supabase CLI local development configuration
├── migrations/          # Incremental, sequential versioned migration files (1-9)
└── README.md            # This documentation file
```

---

## Database Schema Overview

The database uses PostgreSQL with Supabase Auth, Row Level Security (RLS), and Realtime replication.

### Core Tables

| Table | Description | RLS Protected |
|---|---|:---:|
| `profiles` | User profiles 1:1 with `auth.users` (username, full_name, avatar_url, school, bio) | Yes |
| `friends` | Mutual friendships with status (`pending`, `accepted`, `blocked`) | Yes |
| `rooms` | Focus and study rooms with visibility, tags, and durations | Yes |
| `room_members` | Room membership and roles (`host`, `member`) | Yes |
| `focus_sessions` | Focus sessions, goals, duration, and off-task counters | Yes |
| `messages` | Real-time chat messages inside focus rooms | Yes |
| `focus_events` | Domain browsing audit events reported by the Chrome extension | Yes |
| `room_rules` | Allowed and blocked domain lists per room | Yes |
| `user_rules` | Personal domain allow/block override lists per user | Yes |
| `user_settings` | Notification, privacy, and appearance preferences | Yes |
| `user_focus_settings` | Strictness, grace period, and break request preferences | Yes |
| `room_member_focus` | Real-time active focus snapshot (`on-task`, `warning`, `locked`, `approved-break`) | Yes |
| `extension_devices` | Linked Chrome extension browser devices | Yes |

---

## Recommended Setup Procedure

### 1. Diagnose Your Live Database (Read-Only)
Run [`diagnostic.sql`](./diagnostic.sql) in the Supabase SQL Editor. It will report any missing tables, missing columns (such as `rooms.tags`), RPC functions, and publication memberships.

### 2. Apply Master Setup & Repair
Run [`setup_supabase.sql`](./setup_supabase.sql) in the Supabase SQL Editor.
* Safe to run on empty, partially migrated, or existing databases.
* Automatically adds missing columns with `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`.
* Cleans up ambiguous `create_room` RPC function overloads.
* Updates RLS policies, triggers, and Realtime publications without errors.

### 3. Verify Database Health
Run [`verify_setup.sql`](./verify_setup.sql) in the Supabase SQL Editor.
* Confirms all 13 tables exist with RLS enabled.
* Confirms critical columns and RPC functions are active.
* Confirms Realtime publication contains `rooms`, `room_members`, `messages`, and `room_member_focus`.

### 4. (Optional) Run Seed Data
If you want sample rooms and default room rules populated for testing, run [`seed.sql`](./seed.sql).
*(Note: Seed rooms link to existing profiles; ensure at least one user is registered or testing locally).*
