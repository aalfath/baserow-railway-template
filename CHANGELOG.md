# Changelog

Every change merged to `main` reaches people who deployed this template as an "update available" notice in Railway. Breaking changes are listed first in each entry.

## 2.4.3 (2026-11-16)

- First release: Baserow 2.4.3 (`baserow/baserow:2.4.3@sha256:304bebe22bf4c66d96d11bb746727492fa91637bd6deb807b2ef464f071c215c`) with Railway Postgres and Redis.
- The start script runs migrations, creates the admin from `BASEROW_ADMIN_EMAIL` / `BASEROW_ADMIN_PASSWORD` and turns public sign-up off before Baserow listens on `PORT`.
