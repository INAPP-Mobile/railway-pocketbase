# PocketBase Railway Template
# https://github.com/INAPP-Mobile/railway-pocketbase

FROM alpine:3.24 AS builder

ARG PB_VERSION=0.39.5

RUN apk add --no-cache ca-certificates unzip wget \
    && wget -q https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip \
    && unzip pocketbase_${PB_VERSION}_linux_amd64.zip -d /pb \
    && rm pocketbase_${PB_VERSION}_linux_amd64.zip

FROM alpine:3.24

RUN apk add --no-cache ca-certificates

COPY --from=builder /pb/pocketbase /usr/local/bin/pocketbase
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

ENV PORT=8080

# First-boot superuser seeding (idempotent) — see docker-entrypoint.sh for details.
# CMD is wrapped in `sh -c` so ${PORT} / ${PB_DATA} expand at runtime thanks to
# the ENTRYPOINT entrypoint.sh calling exec "$@" with these tokens.
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["sh", "-c", "pocketbase serve --http=0.0.0.0:${PORT:-8080} --dir=${PB_DATA:-/pb_data}"]
