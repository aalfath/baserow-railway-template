[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/baserow?utm_medium=integration&utm_source=button&utm_campaign=baserow)

# Baserow on Railway

A Railway template for [Baserow](https://baserow.io), the open-source no-code database and Airtable alternative.

It deploys Baserow **2.4.3**: the official `baserow/baserow` all-in-one image, pinned by digest in the [`Dockerfile`](Dockerfile), with Railway's own Postgres and Redis.

## What gets deployed

| Service | Source | Notes |
|---|---|---|
| Baserow | this repo (`Dockerfile`) | Public HTTPS domain; volume on `/baserow/data` for uploaded files and Baserow's own settings |
| Postgres | Railway Postgres | Baserow's database |
| Redis | Railway Redis | Cache, real-time updates and background jobs |

The all-in-one image runs Caddy, the Django backend, Celery workers and the Nuxt web frontend under supervisord. It uses about 2 GB of RAM once it's running.

## Your admin account

Baserow normally makes the **first person to sign up** its instance-wide admin, and sign-up is open by default, so on a fresh public URL that could be anyone. This template's start script ([`railway/start.sh`](railway/start.sh)) closes that gap. Before the web server starts listening, it:

1. runs the database migrations;
2. if the database has no users yet, creates the admin from `BASEROW_ADMIN_EMAIL` and `BASEROW_ADMIN_PASSWORD`, and turns public sign-up off ([`railway/seed_admin.py`](railway/seed_admin.py));
3. starts Baserow as the upstream image does.

If the database is empty and either variable is missing, the service refuses to start rather than open an unclaimed instance. Once users exist, the script changes nothing: passwords and the sign-up setting (Admin → Settings) stay as you set them.

Log in with the email you entered at deploy time and the generated password, which you'll find in the Baserow service's **Variables** tab as `BASEROW_ADMIN_PASSWORD`. Change it under your account settings afterwards if you like.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `BASEROW_ADMIN_EMAIL` | *(you enter it)* | Email of the admin account created on first boot |
| `BASEROW_ADMIN_PASSWORD` | generated secret | Password of that admin account (first boot only) |
| `BASEROW_PUBLIC_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Baserow's public URL, used in links and emails |
| `SECRET_KEY` | generated secret | Django secret key |
| `BASEROW_JWT_SIGNING_KEY` | generated secret | Signs login tokens |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Postgres over Railway's private network |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` | Redis over Railway's private network |

Optional extras, such as SMTP for invitations and password-reset emails (`EMAIL_SMTP`, `EMAIL_SMTP_HOST`, `EMAIL_SMTP_PORT`, `EMAIL_SMTP_USER`, `EMAIL_SMTP_PASSWORD`, `EMAIL_SMTP_USE_TLS`, `FROM_EMAIL`), are listed in [Baserow's configuration docs](https://baserow.io/docs/installation/configuration). Add them to the Baserow service when you need them.

## Railway details

- Caddy listens on Railway's `PORT` over plain HTTP; Railway's edge provides HTTPS. The start script unsets `PORT` before Baserow starts, because the Nuxt frontend would otherwise try to bind the same port.
- Health check: `/_health`. On the very first boot, while the initial migrations run (2–4 minutes), a placeholder answers that path and nothing else. Later boots go live only once Baserow itself answers.
- Custom domain: add it in Railway, then set `BASEROW_PUBLIC_URL` to `https://your-domain.example` and redeploy.

## Updates

This template builds from this repo, so Railway offers an update to everyone who deployed it whenever a change is merged to `main`. Each update bumps the pinned Baserow version and is described in [`CHANGELOG.md`](CHANGELOG.md). Read it before applying an update: Baserow runs its database migrations on start, and they can't be rolled back by redeploying an older version, so back up first (Postgres backups in Railway, plus the `/baserow/data` volume).

## Local test

```sh
docker build -t baserow-railway .
```

Run it with the variables above, a Postgres and a Redis, and a volume on `/baserow/data`.

## License

The wrapper files in this repo are MIT licensed. Baserow itself is licensed by Baserow B.V. (MIT for the open-source edition); see [its repository](https://github.com/baserow/baserow).
