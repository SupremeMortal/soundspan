# Reverse Proxy and Cloudflare Tunnel Setup

This guide covers routing for soundspan, including Listen Together Socket.IO traffic.
It applies to any split frontend/backend deployment model (Kubernetes individual mode, docker-compose with separate `frontend` + `backend` services, or manual container setups).

Important for pre-published frontend images:

- `NEXT_PUBLIC_API_URL` and `NEXT_PUBLIC_API_PATH_MODE` are build-time variables.
- Changing them at container runtime does not change browser routing behavior.
- Use edge reverse-proxy path routing for backend-direct API access.

## Why this matters

When frontend and backend are separate services, Socket.IO traffic still has to reach backend somehow.
soundspan now handles this by default through the frontend runtime proxy.

Listen Together uses:

- namespace: `/listen-together`
- Socket.IO path: `/socket.io/listen-together`
- default transport policy: websocket-only (`LISTEN_TOGETHER_ALLOW_POLLING=false`)

By default, requests to this path can terminate on frontend, which forwards them to backend.
Listen Together preflights this route and blocks create/join with an explicit routing error banner when it is misconfigured.

## Required routing

### Default (recommended): Route all traffic to frontend

For split frontend/backend deployments:

- Route all app traffic (including `/socket.io/listen-together`) to frontend service (`:3030`)
- Frontend proxies `/socket.io/listen-together` to backend service (`:3006`)
- Route `/api/*` to frontend when using frontend proxy mode (works without `NEXT_PUBLIC_*` runtime env overrides)

### Optional: Direct backend path-split routing

Use this when you want backend-direct API paths with pre-published frontend images (no custom frontend rebuild):

- Route `/api/*` (Prefix) to backend service (`:3006`)
- Route `/socket.io/listen-together` (Prefix) to backend service (`:3006`)
- Route all other app traffic (for example `/`) to frontend service (`:3030`)

This route split is the runtime-safe replacement for trying to set `NEXT_PUBLIC_API_URL` / `NEXT_PUBLIC_API_PATH_MODE` on a prebuilt image.
If you do want true in-app `direct` mode, publish a custom frontend image built with the desired `NEXT_PUBLIC_*` values.

For single-service deployments (all-in-one image, Helm `deploymentMode: aio`):

- Route everything to the single soundspan service (`:3030`)

## OIDC callback routing

First select the app/API layout in the [`OIDC_SSO.md` deployment topology matrix](OIDC_SSO.md#deployment-topology). The matrix states when `OIDC_WEB_BASE_URL` is required. Cross-site app/API deployments on different registrable domains are not supported.

Set `OIDC_REDIRECT_URI` to the public URL that users open. Register the same exact value at the identity provider:

```env
OIDC_REDIRECT_URI=https://soundspan.example.com/api/auth/oidc/callback
```

The callback path must reach the backend. The default examples below send `/api/*` through the frontend proxy. The direct path-split examples send `/api/*` straight to the backend. Both patterns deliver `/api/auth/oidc/callback` correctly.

Keep the public scheme, host, port, and path identical in soundspan and the identity provider. Do not use a container-only hostname in `OIDC_REDIRECT_URI`.

When the callback origin differs from the web origin but remains same-site, set the canonical web origin:

```env
OIDC_REDIRECT_URI=https://api.example.com/api/auth/oidc/callback
OIDC_WEB_BASE_URL=https://music.example.com
```

Set `SECURE_COOKIES=true` when the browser uses HTTPS, including when Cloudflare or another edge terminates TLS.

## Request body size

Two uploads send request bodies of several megabytes: profile pictures (up to
5 MiB) and backup restores, which upload the file in 4 MiB pieces. Your proxy
must accept bodies of at least 6 MB. NGINX accepts 1 MB by default, so the
examples below set `client_max_body_size 8m;`.

## NGINX example (Docker/Kubernetes edge)

```nginx
server {
    listen 443 ssl http2;
    server_name soundspan.example.com;
    client_max_body_size 8m;

    # Everything -> frontend (frontend proxies Listen Together socket path)
    location / {
        proxy_pass http://soundspan-frontend:3030;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Optional direct path-split variant:

```nginx
server {
    listen 443 ssl http2;
    server_name soundspan.example.com;
    client_max_body_size 8m;

    location /api/ {
        proxy_pass http://soundspan-backend:3006;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /socket.io/listen-together {
        proxy_pass http://soundspan-backend:3006;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }

    location / {
        proxy_pass http://soundspan-frontend:3030;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

If your reverse proxy already fronts a Helm ingress/gateway, you can point it at the ingress entrypoint and let Helm path rules handle any optional direct socket split.

## Caddy example

```caddy
soundspan.example.com {
    reverse_proxy soundspan-frontend:3030
}
```

Optional direct path-split variant:

```caddy
soundspan.example.com {
    @api path /api/*
    reverse_proxy @api soundspan-backend:3006

    @listenTogether path /socket.io/listen-together*
    reverse_proxy @listenTogether soundspan-backend:3006

    reverse_proxy soundspan-frontend:3030
}
```

## Cloudflare Tunnel example (`cloudflared`)

`cloudflared` supports websocket transport.
For default mode, route hostname to frontend.

```yaml
ingress:
  - hostname: soundspan.example.com
    service: http://soundspan-frontend.soundspan.svc.cluster.local:3030
  - service: http_status:404
```

Optional direct path-split variant (regex path matcher):

```yaml
ingress:
  - hostname: soundspan.example.com
    path: /socket.io/listen-together.*
    service: http://soundspan-backend.soundspan.svc.cluster.local:3006
  - hostname: soundspan.example.com
    service: http://soundspan-frontend.soundspan.svc.cluster.local:3030
  - service: http_status:404
```

Notes:

- If your tunnel points to an existing reverse proxy/ingress, configure this path split there instead of in `cloudflared`.
- Keep websocket-friendly timeouts on any proxy layer between Cloudflare and soundspan.

## Hosting the app's web build

The [soundspan app](CLIENT_APPS.md) also has a web build. It is optional: the soundspan web UI stays the server's main browser interface, and the server image does not include the app. Each app release publishes the web build as a container image, `ghcr.io/soundspan/soundspan-client-web:<version>`, and as a static bundle, `soundspan-<version>-web.tar.gz`, on the [GitHub releases page](https://github.com/soundspan/soundspan/releases).

The image is NGINX serving the app under `/app/` on port `8080`. `/` and `/app` redirect to `/app/`, and `/healthz` answers `200 ok` for health checks. It runs as any user ID in group 0, also with a read-only root filesystem and a tmpfs on `/tmp`, and reads no environment variables:

```bash
docker run -d --name soundspan-client-web --read-only --tmpfs /tmp -p 8080:8080 \
  ghcr.io/soundspan/soundspan-client-web:<version>
```

### On the server's own origin (recommended)

Route `/app/` to the image and leave the routing of every other path as it is. The app then runs on the same origin as the server, so no CORS setting is needed. Pass the path through unchanged: the image expects it to start with `/app/`.

NGINX, added to the `server` block of the examples above:

```nginx
    location /app/ {
        proxy_pass http://soundspan-client-web:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
```

Caddy:

```caddy
soundspan.example.com {
    @app path /app/*
    reverse_proxy @app soundspan-client-web:8080

    reverse_proxy soundspan-frontend:3030
}
```

Users open `https://soundspan.example.com/app/` and enter `https://soundspan.example.com` as the server address.

### On another origin

Serve the image on its own host name, for example `https://app.example.com`, with the app at `https://app.example.com/app/`. The browser then sends cross-origin requests to the server, which the backend refuses unless the app's origin is listed in `ALLOWED_ORIGINS` (comma-separated, see [`CONFIGURATION_AND_SECURITY.md`](CONFIGURATION_AND_SECURITY.md)):

```env
ALLOWED_ORIGINS=https://app.example.com
```

Keep any origins already listed there. When the origin is missing, the app's connection screen says that the server could not be reached and shows the origin to add.

### Headers the image sends

You do not need to add caching or security headers in your proxy:

- `Cache-Control: public, max-age=31536000, immutable` for files whose names carry a content hash, and `no-cache` with an `ETag` for everything else, `index.html` and Flutter's unhashed scripts included, so a redeployed version is picked up at once.
- `Content-Security-Policy: default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; connect-src *; img-src * blob: data:; media-src *; style-src 'self' 'unsafe-inline'; worker-src 'self' blob:`. `connect-src`, `img-src` and `media-src` allow any host because each user chooses the server in the app.
- `X-Content-Type-Options: nosniff` and `Referrer-Policy: no-referrer`.

The static bundle, served by your own web server under `/app/`, needs the same headers.

### Limits of the web build

The web build signs in with a password only: single sign-on, device-link codes and API keys are not available in a browser, so users of a single-sign-on-only server use a native app or the web UI. It cannot download music, and playback stops when the browser tab is closed.

## Verification checklist

1. Open browser devtools Network tab.
2. Visit Listen Together page and join/create a session.
3. Confirm socket handshake requests use `/socket.io/listen-together`.
4. Confirm requests return success and websocket upgrade is established.
5. Confirm UI state changes from `Connecting...` to connected (and no routing error banner appears).
6. Optional direct probe (when polling fallback is enabled): open `/socket.io/listen-together/?EIO=4&transport=polling` in browser.
7. If using default websocket-only policy (`LISTEN_TOGETHER_ALLOW_POLLING=false`), validate by confirming a successful websocket upgrade in browser devtools instead of polling probe.

## Common failure signs

- Repeating frontend logs with `TypeError: fetch failed` when backend path is unreachable.
- Listen Together permanently showing `Connecting...`.
- Listen Together page shows a routing error banner and create/join buttons stay disabled.
- Socket.IO polling requests returning 404/502 from the wrong upstream.

---

## See also

- [Deployment Guide](DEPLOYMENT.md) — Docker and compose deployment options
- [Kubernetes Guide](KUBERNETES.md) — Helm deployment and HA rollout
- [Configuration and Security](CONFIGURATION_AND_SECURITY.md) — External access settings and CORS configuration
- [OIDC and SSO](OIDC_SSO.md) — Identity-provider and callback setup
