# derper

English | [简体中文](README.zh-CN.md)

Auto-built Docker image for [Tailscale DERP server](https://tailscale.com/kb/1118/custom-derp-servers), tracking upstream `tailscale/tailscale` releases.

```bash
docker pull ghcr.io/keveon/derper:latest
```

## Tags

| Tag | Description |
|-----|-------------|
| `latest` | Always the latest Tailscale release |
| `v1.102.2` | Pinned to a specific Tailscale version |

Multi-arch: `linux/amd64`, `linux/arm64`.

## How It Works

GitHub Actions runs daily, checks `tailscale/tailscale` for new releases, and builds a fresh image if a new version is detected.

```
tailscale/tailscale releases v1.102.2
  → Actions detects new version
  → docker build with DERP_VERSION=v1.102.2
  → push to ghcr.io/keveon/derper:v1.102.2 + :latest
```

No source code is stored in this repo — only the Dockerfile that compiles `tailscale.com/cmd/derper` from upstream.

## Usage

The image entrypoint is just `derper`. Pass any CLI flag derper supports — see [Custom DERP Servers](https://tailscale.com/kb/1118/custom-derp-servers) and `derper -h` for the full list.

### Basic

```bash
docker run -d \
  --name derper \
  --restart always \
  -p 443:443 -p 3478:3478/udp \
  -v derper-data:/app/data \
  ghcr.io/keveon/derper:latest \
  --hostname=derp.example.com
```

### With client verification

`--verify-clients` requires access to a local tailscaled daemon via its Unix socket. Mount the host's tailscale socket directory into the container:

```bash
docker run -d \
  --name derper \
  --restart always \
  -p 443:443 -p 3478:3478/udp \
  -v derper-data:/app/data \
  -v /var/run/tailscale:/var/run/tailscale:ro \
  ghcr.io/keveon/derper:latest \
  --hostname=derp.example.com \
  --verify-clients
```

> The host must have `tailscaled` running so that `/var/run/tailscale/tailscaled.sock` exists.

### Volumes

| Path | Required when | Description |
|------|---------------|-------------|
| `/app/data` | Always | DERP config/private key (auto-generated if missing) |
| `/app/certs` | `--certmode=letsencrypt` | ACME certificates |
| `/var/run/tailscale` | `--verify-clients` | tailscaled Unix socket (mount from host, read-only) |

## Manual Build Trigger

Go to **Actions** → **Build and Push Derper Image** → **Run workflow**. Optionally specify a Tailscale version tag.

## License

The derper binary is built from [tailscale/tailscale](https://github.com/tailscale/tailscale) (BSD-3-Clause). This repo's Dockerfile and workflow are MIT-0.
