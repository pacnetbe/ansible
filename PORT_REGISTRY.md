# Port Registry

## Network hosts

| Host | IP |
|---|---|
| pi4-01 | 10.10.10.26 |
| pi5-01 | 10.10.10.29 |
| pserver04 | 10.10.10.28 |
| pserver2502 | 10.10.10.25 |
| vserver04 | 10.10.10.47 |

## Port assignments

| App | Container Port | pi4-01 | pi5-01 | pserver04 | pserver2502 | Notes |
|---|---|---|---|---|---|---|
| Traefik HTTP | 80 | 80 | 80 | 80 | 80 | All hosts |
| Traefik HTTPS | 443 | 443 | 443 | 443 | 443 | All hosts |
| Traefik Dashboard | 8080 | 8080 | 8080 | 8080 | 8080 | via traefik.<host>.lan |
| Portainer CE | 9443 | 9443 | 9443 | 9443 | 9443 | |
| Portainer Edge | 8000 | 8000 | 8000 | 8000 | 8000 | |
| Portainer Agent | 9001 | 9001 | - | 9001 | 9001 | |
| UptimeKuma | 3001 | 3001 | - | 3001 | - | kuma.lan → pi4-01 |
| Homepage | 3000 | - | - | 3010 | - | homepage.lan → pserver04 |
| Dashy | 8080 | 4000 | - | 4000 | - | dashy.lan → pi4-01 (eval) |
| IT-Tools | 80 | - | - | 8081 | - | it-tools.lan → pserver04 |
| Wallos | 80 | - | - | 8282 | - | wallos.lan → pserver04 |
| Beszel | 8090 | - | - | 8090 | - | beszel.lan → pserver04 |
| Netbox | 8080 | - | - | 8010 | - | netbox.lan → pserver04 |
| Frigate Web | 5000 | - | - | - | 5000 | frigate.lan → pserver2502 |
| Frigate RTSP | 8554 | - | - | - | 8554 | Direct, not via Traefik |
| Frigate WebRTC | 8555 | - | - | - | 8555 | Direct, not via Traefik |
| Beszel Agent | - | - | - | - | - | No port exposed |
| Twingate | - | - | - | - | - | No port exposed |
| Netdata | - | - | - | - | - | No port exposed |

## Traefik subdomains (via DNS wildcard *.hostname.lan)

| URL | Host | App |
|---|---|---|
| https://traefik.pi4-01.lan | pi4-01 | Traefik dashboard |
| https://traefik.pi5-01.lan | pi5-01 | Traefik dashboard |
| https://traefik.pserver04.lan | pserver04 | Traefik dashboard |
| https://traefik.pserver2502.lan | pserver2502 | Traefik dashboard |
| https://kuma.lan | pi4-01 | UptimeKuma (primary) |
| https://frigate.lan | pserver2502 | Frigate NVR |
| https://portainer.lan | pi5-01 | Portainer CE (primary) |

## Rules
- Ports 80, 443, 8080 reserved for Traefik on all hosts
- New containers must avoid these ports
- Direct ports kept alongside Traefik labels for HA fallback
- pfSense DNS wildcard *.hostname.lan → host IP → Traefik routes internally
- App-only subdomains (kuma.lan) → pfSense Host Override → primary host

## To do
- [ ] Add remaining pserver04 apps behind Traefik
- [ ] Add Dashy on pi4-01
- [ ] Let's Encrypt via Cloudflare
- [ ] Authelia SSO

