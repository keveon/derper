# syntax=docker/dockerfile:1

# ---- 构建阶段：从 Tailscale 源码编译 derper ----
FROM golang:alpine AS builder

# derper 版本号，由 GitHub Actions 注入（如 v1.102.2）
ARG DERP_VERSION=latest

# alpine 上编译 CGO 程序需要 gcc + musl-dev
RUN apk add --no-cache git gcc musl-dev

WORKDIR /build

# 拉取指定版本的 derper 源码并编译
# Tailscale module 路径为 tailscale.com/cmd/derper
RUN if [ "$DERP_VERSION" = "latest" ]; then \
      go install tailscale.com/cmd/derper@latest; \
    else \
      go install tailscale.com/cmd/derper@"$DERP_VERSION"; \
    fi

# ---- 运行阶段：最小化镜像 ----
FROM alpine:3.22

# derper 依赖 ca-certificates 做 TLS 验证
# tzdata 确保日志时间戳正确
RUN apk add --no-cache ca-certificates tzdata && \
    adduser -D -h /app appuser

WORKDIR /app

# 创建证书目录 + 配置目录
# derper 启动时若配置文件不存在会自动生成 DERP 私钥
RUN mkdir -p /app/certs /app/data && \
    chown -R appuser:appuser /app/certs /app/data

COPY --from=builder /go/bin/derper /usr/local/bin/derper

USER appuser

# 持久化 DERP 私钥，避免每次重建 Pod 生成新密钥导致客户端断连
VOLUME /app/data

EXPOSE 443 80 3478/udp

# 直接执行 derper，所有配置通过 CLI flag 传入
ENTRYPOINT ["derper"]
