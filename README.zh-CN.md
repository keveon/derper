# derper

[English](README.md) | 简体中文

自动构建的 [Tailscale DERP server](https://tailscale.com/kb/1118/custom-derp-servers) Docker 镜像，跟随上游 `tailscale/tailscale` 版本更新。

```bash
docker pull ghcr.io/keveon/derper:latest
```

## Tags

| Tag | 说明 |
|-----|------|
| `latest` | 始终为最新的 Tailscale 发布版本 |
| `v1.102.2` | 锁定到特定 Tailscale 版本 |

多架构：`linux/amd64`、`linux/arm64`。

## 工作原理

GitHub Actions 每日运行，检查 `tailscale/tailscale` 是否有新版本发布，检测到新版本时自动构建镜像。

```
tailscale/tailscale 发布 v1.102.2
  → Actions 检测到新版本
  → 使用 DERP_VERSION=v1.102.2 构建
  → 推送至 ghcr.io/keveon/derper:v1.102.2 + :latest
```

本仓库不存储源码，仅包含编译 `tailscale.com/cmd/derper` 的 Dockerfile。

## 使用

镜像入口直接是 `derper`，支持透传 derper 的所有 CLI 参数。完整参数列表见[自定义 DERP Servers 文档](https://tailscale.com/kb/1118/custom-derp-servers)或运行 `derper -h`。

### 基本用法

```bash
docker run -d \
  --name derper \
  --restart always \
  -p 443:443 -p 3478:3478/udp \
  -v derper-data:/app/data \
  ghcr.io/keveon/derper:latest \
  --hostname=derp.example.com
```

### 启用客户端验证

`--verify-clients` 需要通过本地 tailscaled 守护进程的 Unix socket 验证客户端身份。将宿主机的 tailscale socket 目录挂载到容器中：

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

> 宿主机必须运行 `tailscaled`，确保 `/var/run/tailscale/tailscaled.sock` 存在。

### 挂载点

| 路径 | 何时需要 | 说明 |
|------|----------|------|
| `/app/data` | 始终需要 | DERP 配置/私钥（不存在时自动生成） |
| `/app/certs` | `--certmode=letsencrypt` | ACME 证书 |
| `/var/run/tailscale` | `--verify-clients` | tailscaled 的 Unix socket（从宿主机挂载，只读） |

## 手动触发构建

进入 **Actions** → **Build and Push Derper Image** → **Run workflow**，可选指定 Tailscale 版本号。

## License

derper 二进制来自 [tailscale/tailscale](https://github.com/tailscale/tailscale)（BSD-3-Clause）。本仓库的 Dockerfile 和 workflow 为 MIT-0。
