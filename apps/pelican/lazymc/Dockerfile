FROM alpine:3.20

RUN apk add --no-cache curl ca-certificates

ARG LAZYMC_VERSION=v0.2.11
RUN curl -fsSL -o /usr/local/bin/lazymc \
      "https://github.com/timvisee/lazymc/releases/download/${LAZYMC_VERSION}/lazymc-${LAZYMC_VERSION}-linux-x64-static" \
    && chmod +x /usr/local/bin/lazymc

COPY wake-server.sh /wake-server.sh
RUN chmod +x /wake-server.sh

WORKDIR /lazymc

ENTRYPOINT ["lazymc"]
CMD ["start", "--config", "/lazymc/lazymc.toml"]
