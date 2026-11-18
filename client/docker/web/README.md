# Web client image

Optional container image of the Flutter web client: nginx serving a prebuilt bundle under `/app/` on port 8080, with the cache and security headers of [doc 10](../../../docs/designs/flutter-client/10-platform-integration.md) (Web). It runs as any UID in group 0, also with a read-only root filesystem plus a tmpfs on `/tmp`, and reads no environment variables. Hosting it for users is described in the operator documentation.

## Build

The image does not build Flutter. Build the bundle for `/app/` and copy it into the build context as `bundle/` (ignored by git):

```bash
cd client
flutter build web --release --base-href /app/
rm -rf docker/web/bundle && cp -r build/web docker/web/bundle
docker build -t soundspan-client-web:dev docker/web
```

## Run

```bash
docker run --rm --read-only --tmpfs /tmp --user 12345:0 -p 8080:8080 soundspan-client-web:dev
```

Open `http://localhost:8080/app/`. `/` redirects there and `/healthz` answers `ok`.

## Smoke test

`smoke.sh` takes an image saved with `docker save | gzip`, runs it as above and checks the redirects, the single-page fallback, the headers, the wasm content type and the health check. CI runs it as the `smoke-web` job of `client-build.yml`.

```bash
docker save soundspan-client-web:dev | gzip > /tmp/web-image.tar.gz
docker/web/smoke.sh /tmp/web-image.tar.gz
```
