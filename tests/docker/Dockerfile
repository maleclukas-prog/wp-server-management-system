FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm

WORKDIR /workspace

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        sudo \
    && rm -rf /var/lib/apt/lists/*

COPY . /workspace

RUN chmod +x /workspace/tests/docker/run-install-smoke.sh

CMD ["/workspace/tests/docker/run-install-smoke.sh"]