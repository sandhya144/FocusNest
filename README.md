# GroupLock (LockIn)

**Focus rooms with real accountability.** Start a study session, set goals, and keep each other on track — with gentle nudges, shared blocklists, and an optional Chrome extension that notices when you wander.

Built with Next.js 16 (App Router), React 19, Node.js/Express, Supabase (Auth + Postgres + Realtime), and Tailwind CSS.

---

## Architecture & Project Structure

The project is structured into clear **`frontend`** and **`backend`** tiers:

```
GroupLock/
├── frontend/                     # Next.js 16 Web Client & Chrome Extension
│   ├── app/                      # App router pages, layouts, and routes
│   │   ├── (app)/                # Authenticated views (home, rooms, friends, history, settings)
│   │   ├── api/                  # Built-in Next.js API endpoints
│   │   ├── login/ & signup/      # Authentication pages
│   │   └── page.tsx              # Landing page
│   ├── components/               # React components & shadcn UI primitives
│   │   ├── room/                 # Study room UI (chat, focus banner, lock overlay)
│   │   └── ui/                   # Shared UI primitives
│   ├── hooks/                    # Custom React hooks (useRoom, useRooms, useSessionTimer)
│   ├── lib/                      # Client utilities & Supabase client helpers
│   ├── extension/                # Companion Chrome Extension (Manifest V3)
│   ├── public/                   # Static assets
│   ├── package.json              # Frontend dependencies and scripts
│   └── README.md                 # Frontend documentation
│
├── backend/                      # Backend API Service & Database
│   ├── db/                       # Complete Database Architecture (PostgreSQL / Supabase)
│   │   ├── schema.sql            # Master unified schema (13 tables, functions, RLS, triggers)
│   │   ├── seed.sql              # Development test seed data
│   │   ├── types.ts              # TypeScript database types
│   │   ├── client.ts             # Supabase & Postgres database clients
│   │   ├── config.toml           # Supabase CLI local development configuration
│   │   ├── README.md             # Complete database documentation
│   │   ├── migrations/           # 9 sequential PostgreSQL migrations
│   │   └── scripts/              # Database helper scripts (db:schema)
│   ├── src/                      # Express REST API Server
│   │   ├── config/               # Environment & configuration
│   │   ├── controllers/          # Business logic (rooms, focus, rules)
│   │   ├── middleware/           # Supabase JWT authentication & error handling
│   │   ├── routes/               # API routes (/api/rooms, /api/focus, /api/rules, /api/health)
│   │   └── server.ts             # Express server entrypoint
│   ├── package.json              # Backend dependencies and scripts
│   ├── tsconfig.json             # Backend TypeScript configuration
│   └── README.md                 # Backend documentation
│
├── docs/                         # Additional project documentation
└── README.md                     # Root project guide
```

---

## Database (`backend/db/`)

The database uses PostgreSQL with Supabase Auth, Row Level Security (RLS), and Realtime replication.

### Core Tables
- `profiles` — User display name, avatar, bio, school
- `friends` — Mutual friend relationships with status (`pending`, `accepted`, `blocked`)
- `rooms` — Study rooms with name, topic, tags, duration, and visibility
- `room_members` — Active participants and roles (`host`, `member`)
- `room_member_focus` — Live focus state per member per room (`on-task`, `warning`, `locked`, `approved-break`)
- `messages` — Real-time room chat
- `focus_sessions` — User study session records, goals, and focus durations
- `focus_events` — Tab drift audit events
- `room_rules` — Allowed and blocked domain lists per room
- `user_rules` — Personal domain allow/block override lists
- `user_settings` & `user_focus_settings` — User preferences and notification settings
- `extension_devices` — Connected browser extension devices

All mutations are protected by Row Level Security policies or the `create_room` RPC function.

---

## Quickstart

### 1. Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the web app.

### 2. Backend Setup

```bash
cd backend
npm install
npm run dev
```

The backend API runs on [http://localhost:5000](http://localhost:5000) with health endpoint at `/api/health`.

### 3. Database Setup

To run the complete database in Supabase:
1. Open your Supabase project SQL Editor.
2. Run [`backend/db/schema.sql`](backend/db/schema.sql).
3. (Optional) Run [`backend/db/seed.sql`](backend/db/seed.sql) to add sample rooms and rules.

---

## Chrome Extension (optional)

1. Open `chrome://extensions` in Google Chrome and enable **Developer mode**.
2. Click **Load unpacked** and select the `frontend/extension/` folder.
3. Open [http://localhost:3000](http://localhost:3000) once while logged in so the extension saves your session origin.

---

## License

MIT
