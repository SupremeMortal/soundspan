# SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
#
# Optional container image of the Flutter web client (doc 10, Web).
# Serves a prebuilt bundle under /app/; it does not build Flutter. The
# build context holds this file, nginx.conf and bundle/, the output of
# `flutter build web --base-href /app/`.
#
# Runs as any UID in group 0 and with a read-only root filesystem plus a
# tmpfs on /tmp: nginx writes only its pid file and temp directories, all
# under /tmp, and logs to stdout and stderr. No environment variables are
# read: the base image's entrypoint (which reads NGINX_* variables and
# rewrites conf.d) is bypassed.

FROM nginx:alpine@sha256:fed7e14be83cbd2661a75cdc5b872d936cf155d46c327084d30b8df19ae88d72

RUN rm -f /etc/nginx/conf.d/default.conf && \
    rm -rf /usr/share/nginx/html/*

COPY nginx.conf /etc/nginx/nginx.conf
COPY bundle/ /usr/share/nginx/html/app/

USER 101

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --start-interval=2s --retries=3 \
    CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/healthz"]

ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
