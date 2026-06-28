# PocketBase Railway Template
# https://github.com/INAPP-Mobile/railway-pocketbase

FROM alpine:3.20 AS builder

ARG PB_VERSION=0.39.5

RUN apk add --no-cache ca-certificates unzip wget \
    && wget -q https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip \
    && unzip pocketbase_${PB_VERSION}_linux_amd64.zip -d /pb \
    && rm pocketbase_${PB_VERSION}_linux_amd64.zip

FROM alpine:3.20

RUN apk add --no-cache ca-certificates

COPY --from=builder /pb/pocketbase /usr/local/bin/pocketbase

EXPOSE 8080

ENV PORT=8080

# Use shell form so $PORT expands at runtime
CMD pocketbase serve --http=0.0.0.0:${PORT} --dir=/pb_data
