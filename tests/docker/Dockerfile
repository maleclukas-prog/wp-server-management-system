FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm

WORKDIR /workspace

RUN set -e; \
    printf 'Acquire::Retries "5";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\nAcquire::ForceIPv4 "true";\n' > /etc/apt/apt.conf.d/99ci-retries; \
    sed -i 's|https://archive.ubuntu.com/ubuntu|http://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list; \
    sed -i 's|https://security.ubuntu.com/ubuntu|http://security.ubuntu.com/ubuntu|g' /etc/apt/sources.list; \
    sed -i '/jammy-backports/d' /etc/apt/sources.list; \
    updated=0; \
    for i in 1 2 3 4 5; do \
        if apt-get update; then \
            updated=1; \
            break; \
        fi; \
        echo "apt-get update attempt $i failed, retrying..."; \
        sleep $((i * 2)); \
    done; \
    if [ "$updated" -ne 1 ]; then \
        echo "apt-get update failed after retries"; \
        exit 1; \
    fi; \
    apt-get install -y --no-install-recommends ca-certificates; \
    update-ca-certificates; \
    apt-get install -y --no-install-recommends \
        bash \
        curl \
        git \
        sudo \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY . /workspace

RUN chmod +x /workspace/tests/docker/run-install-smoke.sh

CMD ["/workspace/tests/docker/run-install-smoke.sh"]