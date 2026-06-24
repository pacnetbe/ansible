# Traefik Deployment

Deploys Traefik v3.3 reverse proxy via Docker Compose.

## Usage
Deploy to all traefik_hosts:
ansible-playbook -i inventory/hosts.ini playbooks/traefik/deploy_traefik.yml

Deploy to specific hosts:
ansible-playbook -i inventory/hosts.ini playbooks/traefik/deploy_traefik.yml -e "deploy_target=pi4-01,pserver04"

## Notes
- Dashboard runs on port 8080 — ensure no other container uses this port before deploying
- Port 80 must also be free on the target host
- All new containers should avoid ports 80 and 8080
