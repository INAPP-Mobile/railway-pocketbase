# PocketBase on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/template/<template-id>)

A production-ready [PocketBase](https://pocketbase.io) template for Railway. PocketBase is an open-source backend-as-a-service (BaaS) that combines a SQLite database, file storage, authentication, admin dashboard, and REST API in a single binary.

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

## Getting Started

1. Click the **Deploy on Railway** button above
2. (Optional) Set `ENCRYPTION_KEY` in the Railway dashboard
3. Wait for deployment to complete
4. Open the deployed URL and navigate to `/_/` to access the admin UI
5. Create your admin account and start building

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
| `/_/` | Admin dashboard |
| `/api/` | REST API root |
| `/api/collections/{name}/records` | Collection records |
| `/api/collections/{name}/records/{id}` | Single record |
| `/api/admins` | Admin management |
| `/api/users` | User management |
| `/api/files/{collection}/{id}/{filename}` | File serving |
| `/api/realtime` | WebSocket real-time endpoint |

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
