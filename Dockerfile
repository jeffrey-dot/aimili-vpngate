FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        iproute2 \
        iptables \
        iputils-ping \
        openvpn \
        psmisc \
        python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY vpngate_manager.py vpn_utils.py proxy_server.py ./

ENV VPNGATE_DATA_DIR=/data \
    LOCAL_PROXY_HOST=0.0.0.0 \
    LOCAL_PROXY_PORT=7928 \
    UI_HOST=0.0.0.0 \
    UI_PORT=8787

EXPOSE 7928 8787

CMD ["python3", "/app/vpngate_manager.py"]
