## Learned User Preferences

- Explain deploy and setup steps in Indonesian when the user asks in Indonesian.
- When given SSH access and domains, expect the agent to perform first-time server deploy end-to-end on the target host.
- Confirm explicit AWS cost acceptance before running `terraform apply` on demo-3-aws.
- Use GitHub Actions for automatic deploy on push to `main` across all demos.
- For demo-2-docker CI/CD, prefer Portainer webhook redeploy over SSH-based deploy.
- Provide domain names and SSH targets when requesting deployment; user sets DNS and GitHub secrets separately.
- After deploy or CI/CD changes, verify end-to-end with tests until everything works.

## Learned Workspace Facts

- Monorepo `fikihfirmansyah/cloud-native-evolution-demo`: demo-1-legacy (Laravel on VPS), demo-2-docker (Docker/Traefik/Portainer), demo-3-aws (Terraform on AWS); demo-2 and demo-3 share app source in `demo-2-docker/`.
- demo-3-aws defaults to AWS region `ap-southeast-1`; provision with Terraform, deploy app via GitHub Actions to ECR/ECS/S3; no app source in `demo-3-aws/` — CI builds from `demo-2-docker/api` and `demo-2-docker/web`.
- demo-1-legacy `setup-vps.sh` supports Ubuntu 22.04 (PHP 8.3) and Debian 12+ (PHP 8.4); writes service names to `/etc/katalog-legacy.env`.
- demo-1 `deploy-jadul.sh` uses `git fetch` + `git reset --hard origin/main` to avoid merge conflicts on the server.
- demo-1 legacy API intentionally omits `/api/health` (part of the legacy demo narrative).
- demo-2-docker `docker-compose.yml` pulls pre-built GHCR images; local builds use `docker-compose.dev.yml` via `make build`.
- demo-2-docker requires Traefik v3.6+ for Docker 29 (Docker API 1.44+ compatibility).
- Portainer webhook deploy for demo-2 starts with 1 API replica; scale to 3 manually before scaling/kill-one demos.
- Demo hostnames under `*.fikihfirmansyah.my.id`: demo-1 `demo-legacy-1`, demo-2 `api-demo-docker-2`/`demo-docker-2`, demo-3 `api-demo-aws-3`/`demo-aws-3`.
- demo-3-aws without CloudFront: frontend on S3 website; set GitHub `VITE_API_BASE` to the HTTPS API URL; with CloudFront use empty `VITE_API_BASE` (same-origin `/api/*`).
- Load tests use `hey` on `/api/produk`; demo-1 `make load` is 20s/100 concurrent, demo-3 `make load` is 5m/150 concurrent; identical hard scenario is `hey -z 5m -c 150`.
