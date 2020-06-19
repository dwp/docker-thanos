FROM alpine:3.12.0 as BASE

ARG THANOS_VERSION=0.12.2

# Dependencies
RUN apk add --update --no-cache \
    curl

# Download prometheus
RUN curl -k -LSs --output /tmp/thanos.tar.gz \
    https://github.com/thanos-io/thanos/releases/download/v${THANOS_VERSION}/thanos-${THANOS_VERSION}.linux-amd64.tar.gz && \
    tar -C /tmp --strip-components=1 -zoxf /tmp/thanos.tar.gz && \
    rm -f /tmp/thanos.tar.gz && \
    mv /tmp/thanos /bin/ && \
    mkdir -p /thanos && \
    chown -R nobody:nogroup /thanos

VOLUME [ "/thanos" ]

WORKDIR /thanos

COPY entrypoint.sh entrypoint.sh

RUN chown nobody:nogroup entrypoint.sh

ENV THANOS_MODE=sidecar

ENTRYPOINT [ ./entrypoint.sh ]
