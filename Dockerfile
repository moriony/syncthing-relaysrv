FROM --platform=$BUILDPLATFORM alpine:3.18.2

ENV DEBUG           false
ENV SERVER_HOST     ""
ENV SERVER_PORT     22067
ENV STATUS_HOST     ""
ENV STATUS_PORT     22070
ENV EXT_ADDRESS     ""
# 10 MBytes/s
ENV RATE_GLOBAL     10000000
# 500 KBytes/s
ENV RATE_SESSION    500000
ENV TIMEOUT_MSG     1m0s
ENV TIMEOUT_NET     2m0s
ENV PING_INT        1m0s
ENV PROVIDED_BY     ""
# Leave empty for private relay, use "https://relays.syncthing.net/endpoint" for public relay
ENV POOLS           ""
ENV ADDITIONAL_OPTS ""
ENV TZ              Etc/UTC

ARG TARGETOS TARGETARCH
ARG BUILD_REQUIREMENTS="curl"
ARG REQUIREMENTS="ca-certificates tzdata"
ARG VERSION="v1.22.1"
ARG DOWNLOAD_URL="https://github.com/syncthing/relaysrv/releases/download/${VERSION}/strelaysrv-${TARGETOS}-${TARGETARCH}-${VERSION}.tar.gz"

WORKDIR /tmp

COPY docker-entrypoint.sh /var/syncthing/docker-entrypoint.sh

RUN apk --no-cache add ${REQUIREMENTS} \
    && apk --no-cache --virtual build-dependencies add ${BUILD_REQUIREMENTS} \
    && curl -Ls ${DOWNLOAD_URL} --output /tmp/strelaysrv.tar.gz \
    && tar -zxf /tmp/strelaysrv.tar.gz \
    && rm /tmp/strelaysrv.tar.gz \
    && cp /tmp/strelaysrv-${TARGETOS}-${TARGETARCH}-${VERSION}/strelaysrv /bin/strelaysrv \
    && rm -rf /tmp/strelaysrv-${TARGETOS}-${TARGETARCH}-${VERSION} \
    && chmod 755 /bin/strelaysrv /var/syncthing/docker-entrypoint.sh \
    && mkdir -p /etc/syncthing \
    && apk del build-dependencies

VOLUME /etc/syncthing

EXPOSE ${STATUS_PORT} ${SERVER_PORT}

HEALTHCHECK --interval=1m --timeout=10s \
  CMD nc -z ${SERVER_HOST} ${SERVER_PORT} || exit 1

ENTRYPOINT [ "/var/syncthing/docker-entrypoint.sh" ]

CMD strelaysrv \
  -keys="/etc/syncthing" \
  -listen="${SERVER_HOST}:${SERVER_PORT}" \
  -status-srv="${STATUS_HOST}:${STATUS_PORT}" \
  -debug="${DEBUG}" \
  -global-rate="${RATE_GLOBAL}" \
  -per-session-rate="${RATE_SESSION}" \
  -message-timeout="${TIMEOUT_MSG}" \
  -network-timeout="${TIMEOUT_NET}" \
  -ping-interval="${PING_INT}" \
  -provided-by="${PROVIDED_BY}" \
  -pools="${POOLS}" \
  -ext-address="${EXT_ADDRESS}" ${ADDITIONAL_OPTS}
