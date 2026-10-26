# GroupLock / LockIn — Setup Guide

## 1. Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

- Open **http://localhost:3000**
- Test demo room, focus state simulations (On task / Warning / Locked / Break), and chat.
- Optional: load the Chrome extension from `frontend/extension/`.

## 2. Backend & Database Setup

```bash
cd backend
npm install
npm run dev
```

- Backend runs on **http://localhost:5000**.
- Complete database schema and migrations are located in `backend/db/`.
- Run `backend/db/schema.sql` in your Supabase SQL editor to deploy all 13 tables, RLS policies, and RPC functions.
