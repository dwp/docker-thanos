FROM thanosio/thanos:master-2021-01-05-0aa07118 AS thanos

FROM alpine:3.12

# ARG THANOS_VERSION=0.17.2

# Dependencies
RUN apk add --update --upgrade --no-cache \
    curl \
    aws-cli \
    openssl>=1.1.1i

# Downwnload thanos
# RUN curl -k -LSs --output /tmp/thanos.tar.gz \
#     https://github.com/thanos-io/thanos/releases/download/v${THANOS_VERSION}/thanos-${THANOS_VERSION}.linux-amd64.tar.gz && \
#     tar -C /tmp --strip-components=1 -zoxf /tmp/thanos.tar.gz && \
#     rm -f /tmp/thanos.tar.gz && \
#     mv /tmp/thanos /bin/ && \
COPY --from=thanos /bin/thanos /bin/thanos
RUN mkdir -p /thanos && \
    mkdir -p /etc/thanos && \
    chown -R nobody:nogroup /etc/thanos /thanos

VOLUME [ "/thanos" ]

WORKDIR /thanos

COPY entrypoint.sh entrypoint.sh

RUN chown nobody:nogroup entrypoint.sh

ENV THANOS_MODE=sidecar

ENTRYPOINT [ "./entrypoint.sh" ]
