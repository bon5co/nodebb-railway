# nodebb-railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/nodebb-or-just-updated-discourse-alterna?referralCode=Z1xivh&utm_medium=integration&utm_source=template&utm_campaign=generic)

**Deploy on Railway:** [NodeBB template](https://railway.com/deploy/nodebb-or-just-updated-discourse-alterna?referralCode=Z1xivh&utm_medium=integration&utm_source=template&utm_campaign=generic)

Railway wrapper image for [NodeBB](https://nodebb.org) 4.15.1 — the open-source forum.

Published as `ghcr.io/bon5co/nodebb-railway`. What it adds over `ghcr.io/nodebb/nodebb`:

- **`config.json` is written with a JSON encoder, not a shell.** The Railway category
  leader builds the file from a start command (`sh -c "... echo $CONFIG_JSON > setup.json ..."`).
  The value is expanded by the outer shell and re-parsed by the inner one, which performs quote
  removal, so NodeBB receives `{database: postgres, url: ...}` and aborts with
  `Error parsing your configuration file`. The container then exits and the forum never serves
  a page.
- **The forum is installed non-interactively before any port is bound.** Upstream's alternative
  is the NodeBB web installer, which means the first stranger to load the public URL creates the
  administrator account.
- **The administrator password is re-applied on every boot**, so a redeploy is a working password
  reset. NodeBB's own recovery path is an emailed link, and a fresh deploy has no SMTP.
- **Refuses to boot without `NODEBB_ADMIN_PASSWORD`.**
- **Volume ownership repaired.** Railway mounts volumes as uid 0; the image runs as uid 1001.
  Config, build output, uploads and the npm cache are relocated onto the single volume and the
  server drops back to uid 1001 with `setpriv`.
- **`trust_proxy` enabled**, so the forum logs and rate-limits the real client rather than
  Railway's edge.
- **Pinned to 4.15.1**, against `:latest` on an application that migrates its schema forward.

## Environment

| Variable | Required | Purpose |
| --- | --- | --- |
| `NODEBB_URL` | yes | Public URL of the forum |
| `NODEBB_SECRET` | yes | Session secret |
| `NODEBB_ADMIN_PASSWORD` | yes | Administrator password, re-applied every boot |
| `NODEBB_ADMIN_USERNAME` | no (`admin`) | Administrator username |
| `NODEBB_ADMIN_EMAIL` | no | Administrator email |
| `NODEBB_DB_HOST` / `_PORT` / `_USER` / `_PASSWORD` / `_NAME` | yes | PostgreSQL connection |
| `NODEBB_DB_SSL` | no (`false`) | PostgreSQL TLS |
| `PORT` | injected | Listen port |

Mount a volume at `/data`.
