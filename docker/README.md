# Docker deployment

This compose stack runs:

- `aimilivpn`: OpenVPN + VPNGate manager + local HTTP/SOCKS5 proxy on Docker network port `7928`.
- `xray`: VLESS + WebSocket inbound on container port `10000`, with outbound traffic sent to `aimilivpn:7928`.

The compose file does not publish host ports. It only exposes container ports for Dokploy or another reverse proxy:

- `xray:10000` for Cloudflare / Dokploy routing.
- `aimilivpn:8787` for the AimiliVPN admin UI if you choose to create a private/internal route.
- `aimilivpn:7928` only for Xray's outbound proxy connection inside the Docker network.

## 1. Prepare the host

```bash
sudo modprobe tun
test -c /dev/net/tun
```

Docker must be able to pass `/dev/net/tun` into the AimiliVPN container. The container also needs `NET_ADMIN` so OpenVPN can create and manage `tun0`.

## 2. Replace the Xray UUID

Edit `docker/xray/config.json` and replace:

```text
7f91df45-7b86-42c4-9f6d-c38e4f4b38cf
```

Generate a new UUID with:

```bash
python3 -c 'import uuid; print(uuid.uuid4())'
```

The default UUID is only a sample.

## 3. Deploy with Dokploy

Create a Compose application in Dokploy using this repository and point Dokploy's public route to:

```text
Service: xray
Container port: 10000
Path used by Xray: /ray
```

Do not expose `aimilivpn:7928` publicly. It is an unauthenticated local proxy and should stay Docker-internal.

The AimiliVPN container needs host TUN access and `NET_ADMIN`. If Dokploy does not pass `devices` / `cap_add` from compose on your setup, enable those advanced container options manually.

## 4. Start locally for testing

```bash
docker compose up -d --build
docker compose logs -f aimilivpn
```

AimiliVPN may need some time to fetch and test VPNGate nodes before the proxy exit is usable.

## 5. Read AimiliVPN admin credentials

```bash
docker compose exec aimilivpn cat /data/ui_auth.json
```

If you need the admin UI in Dokploy, route only a protected/private domain to:

```text
Service: aimilivpn
Container port: 8787
```

Then visit the secret path shown in `/data/ui_auth.json`, for example:

```text
https://your-private-admin-domain.example/EJsW2EeBo9lY/
```

## 6. Cloudflare DNS and client settings

Create an `A` record pointing your domain to the Singapore VPS and enable Cloudflare proxy.

This sample expects Cloudflare / Dokploy to terminate TLS and forward WebSocket traffic to Xray container port `10000`. Client settings:

```text
Protocol: VLESS
Address: your.domain.com
Port: 443
UUID: the UUID in docker/xray/config.json
Transport: WebSocket
Path: /ray
TLS: enabled
SNI/Host: your.domain.com
```

If your Cloudflare SSL/TLS mode is `Full` or `Full (strict)`, make sure Dokploy has a valid origin certificate or uses its own reverse proxy certificate flow.

## 7. Verify the exit IP

From a client connected through Xray, open:

```text
https://ip.sb
```

The visible IP should be the active VPNGate node IP, not the Singapore VPS IP.
