# GroupLock Backend & Database Service

The backend layer for **GroupLock / LockIn** provides:
1. **Database Schema & Migrations** (`backend/db/`) — Complete PostgreSQL/Supabase database schema, RLS policies, triggers, RPCs, seed data, and TypeScript types.
2. **REST API Service** (`backend/src/`) — Node.js / Express API for focus room discovery, activity reporting, tab domain classification, and user/room rule management.

---

## Folder Structure

```
backend/
├── db/                             # Complete Database Layer
│   ├── schema.sql                  # Master SQL schema (all tables, functions, RLS, triggers)
│   ├── seed.sql                    # Sample seed data for development
│   ├── client.ts                   # Supabase database client utilities
│   ├── types.ts                    # Full TypeScript types for all tables & RPCs
│   ├── config.toml                 # Supabase CLI local development config
│   ├── README.md                   # Database schema documentation
│   ├── migrations/                 # Sequential versioned migration files
│   └── scripts/                    # Database helper scripts
├── src/                            # Express Backend Application
│   ├── config/                     # Environment and server configuration
│   ├── controllers/                # Request handlers (rooms, focus, rules)
│   ├── middleware/                 # JWT Auth and error handlers
│   ├── routes/                     # API routes (/api/rooms, /api/focus, /api/rules, /api/health)
│   └── server.ts                   # Server entrypoint
├── .env.example                    # Backend environment template
├── .gitignore                      # Git ignore rules for backend
├── package.json                    # Backend dependencies & scripts
├── tsconfig.json                   # TypeScript configuration
└── README.md                       # This documentation
```

---

## Quickstart

### 1. Environment Configuration

Copy the example environment file and fill in your Supabase credentials:

```bash
cd backend
cp .env.example .env
```

Ensure `.env` contains:
```env
PORT=5000
NODE_ENV=development
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
FRONTEND_URL=http://localhost:3000
```

### 2. Install Dependencies

```bash
cd backend
npm install
```

### 3. Start Development Server

```bash
npm run dev
```

The API will be available at: `http://localhost:5000`

---

## API Endpoints

| Method | Endpoint | Description | Auth Required |
|---|---|---|:---:|
| `GET` | `/api/health` | Healthcheck and server status | No |
| `GET` | `/api/rooms` | List active study & focus rooms | Optional |
| `GET` | `/api/rooms/:id` | Get room details, active members, and rules | Optional |
| `POST` | `/api/rooms` | Create a new room with tags and duration | Yes (Bearer JWT) |
| `POST` | `/api/focus/activity` | Report domain from Chrome extension & classify | Optional / Yes |
| `GET` | `/api/focus/room/:roomId` | Get real-time focus states for all room members | Optional |
| `GET` | `/api/rules` | Get room rules & personal user rules | Yes (Bearer JWT) |
| `POST` | `/api/rules/personal` | Update personal domain allow/block lists | Yes (Bearer JWT) |

---

## Database Management

See [`db/README.md`](./db/README.md) for full details on the PostgreSQL schema, RLS policies, and triggers.

- **Apply full schema**: Run [`db/schema.sql`](./db/schema.sql) in the Supabase SQL editor.
- **Inspect schema**: Run `npm run db:schema`.

