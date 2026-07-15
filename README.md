# PocketBase on Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/new/template/pocketbase-5)

> **Auto-seeded default admin on first deploy**
>
> - **Email:** `admin@example.com`
> - **Password:** `ChangeMePocketbase2026!` (placeholder — **rotate immediately** in `/_/` → **Settings → Admins** after first login; the placeholder is identical across every marketplace deploy of this template).
> - **Auth API (v0.23+):** `POST /api/collections/_superusers/auth-with-password`

A production-ready [PocketBase](https://pocketbase.io) template for Railway — single-binary SQLite + admin UI + REST API. First deploy auto-seeds that admin superuser at `/_/` and you can rotate the password inline from the admin UI. The same login / API surface stays valid through redeploys; only the rotate step needs to happen on day-zero.

## Features

- **Single binary** — PocketBase runs as a single Go binary with zero external dependencies
- **SQLite database** — Built-in database with no separate DB server needed
- **Admin dashboard** — Full-featured admin UI at `/_/`
- **Auth system** — Built-in user authentication with OAuth2 providers
- **File storage** — Built-in file and asset storage
- **Real-time subscriptions** — WebSocket-based real-time data sync
- **Auto HTTPS** — Automatic TLS via Let's Encrypt (when domain set)
- **Extensible** — JavaScript hooks and custom migrations

## Architecture

```
┌─────────────────────────────────────────────┐
│              Railway Container              │
│                                              │
│  ┌─────────────┐      ┌──────────────────┐  │
│  │  PocketBase  │──────│  pb_data volume   │  │
│  │  (binary)     │      │   (SQLite DB,     │  │
│  │               │      │    files, config)  │  │
│  │  Port 8080    │      └──────────────────┘  │
│  └──────┬───────┘                              │
│         │                                      │
│         │ HTTP/REST/WebSocket                   │
│         ▼                                      │
│  ┌──────────────┐                             │
│  │  Admin UI    │                             │
│  │  /_/         │                             │
│  └──────────────┘                             │
└─────────────────────────────────────────────┘
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | No | `8080` | HTTP listen port (Railway sets this automatically) |
| `ENCRYPTION_KEY` | No | — | 32-character hex key for encrypting app settings. Generate with `openssl rand -hex 16` |
| `ADMIN_USER` | No | `admin@example.com` | Email of the first PocketBase superuser. Auto-seeded once on first boot only (when the volume is empty). |
| `ADMIN_PASSWORD` | No | `ChangeMePocketbase2026!` | Initial password (≥5 chars) for the auto-seeded first superuser. Default is a **generic placeholder** that is identical across every marketplace deploy of this template — **rotate from the admin UI immediately after first login** (see First Boot Admin Setup → Rotate below). |

## Getting Started

1. Click the **Deploy on Railway** button above
2. (Optional) Set `ENCRYPTION_KEY` in the Railway dashboard, and optionally `ADMIN_USER` / `ADMIN_PASSWORD` (see **First Boot Admin Setup** below)
3. Wait for deployment to complete
4. Open the deployed URL and navigate to `/_/` to access the admin UI
5. Log in with the seeded credentials OR create your admin account via the wizard

### 💾 First Boot Admin Setup

PocketBase ships **without any default admin credentials** — you must create the first superuser yourself. This template gives you two equivalent ways to do it.

**Path A — Auto-seed via deploy form variables (recommended)**

In the Railway deploy form (or `.env`), set both:

- `ADMIN_USER` — your email (PocketBase CLI enforces valid email format). Default: `admin@example.com`.
- `ADMIN_PASSWORD` — at least 5 characters. **Default placeholder:** `ChangeMePocketbase2026!` — see “Rotate after first login” below before relying on it.

The entrypoint script (`docker-entrypoint.sh`) detects the empty `/pb_data` volume on first boot and runs `pocketbase superuser create "$ADMIN_USER" "$ADMIN_PASSWORD"`. Subsequent deploys leave credentials alone — the script only seeds when `data.db` is absent, so redeploys and restarts are safe. Log in at `https://<your-app>.up.railway.app/_/`.

**Path B — Use the in-app UI**

Path B is harder now that `ADMIN_PASSWORD` ships with a placeholder default. To take this path, **clear both `ADMIN_USER` and `ADMIN_PASSWORD`** (and any other ADMIN_* values) in the deploy form, leaving them blank. PocketBase will then display a *Create your first superuser* wizard on the first visit to `/_/`. Fill it in interactively and you're done.

Tip: the “rotate after first login” expectation (below) applies regardless of which path you chose.

**Recovery / reset**

To re-seed (e.g. after wiping the volume), run from the repo root:

```bash
scripts/railway.sh run --service pocketbase \
  "pocketbase superuser create admin@example.com 'NewStrongPassword' --dir=/pb_data"
```

Or wipe the volume in the Railway dashboard (Service → Settings → Volume → Delete) and redeploy — the entrypoint will auto-seed again if `ADMIN_USER` / `ADMIN_PASSWORD` are set.

**⚠️ Rotate after first login (mandatory for marketplace deploys)**

The shipped default `ADMIN_PASSWORD=ChangeMePocketbase2026!` is a **generic placeholder**. Because Railway template `serializedConfig` is publicly readable, every marketplace deployment of this template starts with **the same initial password** until rotated. Treat the default as compromised on day zero. Two equivalent ways to rotate:

- **From the admin UI (easiest)** — log in at `/_/` with `admin@example.com` / `ChangeMePocketbase2026!`, then **Settings → Admins** → edit your superuser record → set a new password.
- **From the CLI via `railway run`** — `scripts/railway.sh run --service pocketbase "pocketbase superuser upsert admin@example.com 'YOUR_NEW_PASSWORD' --dir=/pb_data"`

After rotating, optionally also update the `ADMIN_PASSWORD` env var on the Railway dashboard to match, so any environment-aware tooling (e.g. the API curl example below) references the latest value. Redeploys leave the rotated password alone — the entrypoint only re-seeds when `data.db` is absent.

**Programmatic login (cURL)**

```bash
curl -X POST https://<your-app>.up.railway.app/api/collections/_superusers/auth-with-password \
  -H 'Content-Type: application/json' \
  -d '{"identity":"<ADMIN_USER>","password":"<ADMIN_PASSWORD>"}'
```

Expected response:

```json
{"token":"<JWT>","admin":{"id":"...","email":"<ADMIN_USER>"}}
```

The returned `token` is a JWT you can pass as `Authorization: <token>` to `/api/collections/...` calls (e.g. listing collections, managing records).

### Local Development

```bash
# Clone the repo
git clone https://github.com/INAPP-Mobile/railway-pocketbase.git
cd railway-pocketbase

# Build and run with Docker
docker build -t pocketbase .
docker run -p 8080:8080 -v ./pb_data:/pb_data pocketbase
```

## API Endpoints

Once deployed, PocketBase exposes the following endpoints:

| Endpoint | Description |
|----------|-------------|
| `/_/` | Admin dashboard (SPA + onboarding wizard on first boot) |
| `/api/` | REST API root |
| `/api/health` | API health probe — returns `200 {"message":"API is healthy.","code":200}` |
| `/api/collections/{name}/records` | Collection records (list/create) |
| `/api/collections/{name}/records/{id}` | Get/update/delete a single record |
| `/api/collections/{name}/auth-with-password` | Password-auth on any collection (incl. `_superusers`) — `POST {"identity":...,"password":...}` returns a JWT |
| `/api/collections/_superusers` | Superuser management |
| `/api/files/{collection}/{id}/{filename}` | File serving |
| `/api/realtime` | WebSocket real-time endpoint |

**📌 Note (PocketBase v0.23+ — breaking change):** The legacy "admin" routes were removed. `/api/admins/*` and `/api/collections/_admins/*` both return **404 not found** on v0.39.5. The canonical superuser auth endpoint is now:

```http
POST /api/collections/_superusers/auth-with-password
Content-Type: application/json

{"identity":"<ADMIN_USER>","password":"<ADMIN_PASSWORD>"}
```

Expected response (`200 OK`):

```json
{"token":"<JWT>","admin":{"id":"...","email":"<ADMIN_USER>"}}
```

The same `/api/collections/{name}/auth-with-password` pattern works for any user collection (`/api/collections/users/...`, etc.).

## Deploy and Host

### About Hosting

This template deploys PocketBase on Railway, a cloud platform that handles infrastructure, scaling, and HTTPS automatically. Railway manages the container lifecycle, networking, and provides a `$PORT` environment variable for the listen address.

### Why Deploy

- **Zero DevOps** — No server configuration, no database setup, no SSL management
- **Single binary** — PocketBase's all-in-one design means no external services to manage
- **Built-in everything** — Database, auth, file storage, and admin UI included
- **Cost effective** — SQLite eliminates the need for a separate database service
- **Rapid prototyping** — Go from idea to running API in minutes

### Common Use Cases

- Personal API backend and data service
- Internal tool admin panels
- Mobile app backends
- Small to medium web application backends
- Prototyping and MVP development
- Content management for static sites
- File hosting with built-in storage

## Dependencies for PocketBase

### Deployment Dependencies

- **Railway** — Cloud hosting platform (handles container orchestration, networking, HTTPS)
- **Docker** — Container runtime for building and running the image locally

### Runtime Dependencies

PocketBase is a self-contained Go binary that embeds:

- **SQLite** — Embedded database engine
- **Web server** — HTTP/HTTPS server with Let's Encrypt auto-TLS
- **Admin UI** — SPA admin dashboard (built-in)
- **JS runtime** — Goja JavaScript runtime for hooks

No external databases, caching layers, or message queues are required.

## Troubleshooting

### Container crashes immediately

Ensure the `pb_data` volume is mounted. The container expects a writable `/pb_data` directory.

### 502 Bad Gateway from Railway

Railway's health check may not match PocketBase's startup time. Check the deploy logs — the first startup can take a few seconds while the admin UI assets are initialized.

### Cannot access admin UI at `/_/`

- Verify the deployment is healthy in Railway dashboard
- Check that the `PORT` environment variable is set correctly
- Try clearing browser cache or using an incognito window

### Database performance

SQLite is file-backed and performs best with a single writer. For very high concurrency workloads, consider using PocketBase in read-replica mode or with a connection pooler.

### Migration errors

PocketBase applies migrations automatically by default. If you encounter migration conflicts, use `--automigrate=false` and run migrations manually.

## License

This template is provided under the MIT License. PocketBase itself is MIT licensed.
