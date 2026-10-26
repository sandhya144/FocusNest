# GroupLock Frontend (Next.js 16 + React 19)

Focus rooms with real-time peer accountability, powered by Next.js 16 (App Router), React 19, Tailwind CSS v4, and Supabase client.

## Tech Stack

- **Framework**: Next.js 16 (Turbopack, App Router, Server Components)
- **UI Library**: React 19, Tailwind CSS v4, Lucide Icons, Radix/shadcn UI
- **State & Realtime**: Supabase Client (Auth, Realtime channel subscriptions)
- **Forms & Validation**: React Hook Form, Zod

## Structure

```
frontend/
├── app/                      # Next.js App Router
│   ├── (app)/                # Authenticated application shell
│   │   ├── home/             # User dashboard & study room discovery
│   │   ├── rooms/            # Room directory, room detail [id], and new room creation
│   │   ├── friends/          # Friend activity & management
│   │   ├── history/          # Focus session records
│   │   └── settings/         # Profile & accountability settings
│   ├── api/                  # API routes (activity classification, focus events, rules)
│   ├── login/ & signup/      # Authentication pages
│   ├── globals.css           # Tailwind styling
│   └── layout.tsx            # Root layout with theme provider
├── components/               # React components
│   ├── room/                 # Study room UI (chat panel, member list, focus badges, lock overlay)
│   ├── settings/             # Settings shell
│   ├── ui/                   # Reusable UI primitives (dialog, button, avatar, input, tabs, etc.)
│   └── app-nav.tsx           # Global navigation bar
├── hooks/                    # Custom React hooks (useRoom, useRooms, useSessionTimer)
├── lib/                      # Utilities & helpers
│   ├── supabase/             # Supabase browser, server, and middleware clients
│   ├── demo-activity-store.ts# In-memory activity fallback store
│   └── validators.ts         # Zod schemas
├── extension/                # Companion Chrome Extension (Manifest V3)
├── public/                   # Static assets
└── package.json
```

## Getting Started

### 1. Configure Environment
Create a `.env.local` file inside `frontend/`:

```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

### 2. Install & Run

```bash
cd frontend
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### 3. Build for Production

```bash
npm run build
npm run start
```

