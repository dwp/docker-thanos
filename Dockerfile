FROM alpine:3.16

ARG THANOS_VERSION=0.28.0

# Dependencies
RUN apk add --update --upgrade --no-cache \
    curl \
    aws-cli \
    openssl

# Download thanos
RUN curl -k -LSs --output /tmp/thanos.tar.gz \
    https://github.com/thanos-io/thanos/releases/download/v${THANOS_VERSION}/thanos-${THANOS_VERSION}.linux-amd64.tar.gz && \
    tar -C /tmp --strip-components=1 -zoxf /tmp/thanos.tar.gz && \
    rm -f /tmp/thanos.tar.gz && \
    mv /tmp/thanos /bin/ && \
    mkdir -p /thanos && \
    mkdir -p /data && \
    mkdir -p /etc/thanos && \
    chown -R nobody:nogroup /etc/thanos /thanos /data

WORKDIR /thanos

COPY entrypoint.sh entrypoint.sh

RUN chown nobody:nogroup entrypoint.sh

ENV THANOS_MODE=sidecar

EXPOSE 10901

ENTRYPOINT [ "./entrypoint.sh" ]
