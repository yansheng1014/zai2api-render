#!/usr/bin/env bash
# Z.AI2API — Linux one-click launcher (开箱即用)
set -e
cd "$(dirname "$0")"

PORT_DEFAULT=8088

# ── 0. mihomo 代理内核：优先使用包内自带，否则自动下载（平滑回退）──
# 先补齐执行位（Windows 打包的 tar 不带 +x），避免误触发下载覆盖包内二进制
chmod +x ./mihomo ./zai2api ./token-collector 2>/dev/null || true
if [ ! -f ./mihomo ]; then
    echo "[start] 未找到包内 mihomo，尝试自动下载纯净二进制..."
    VER=$(curl -fsSL https://api.github.com/repos/MetaCubeX/mihomo/releases/latest 2>/dev/null \
          | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)
    VER=${VER:-v1.19.29}
    URL="https://github.com/MetaCubeX/mihomo/releases/download/${VER}/mihomo-linux-amd64-compatible-${VER}.gz"
    if curl -fsSL "$URL" -o /tmp/mihomo.gz && gunzip -f /tmp/mihomo.gz; then
        mv /tmp/mihomo ./mihomo
        echo "[start] mihomo ${VER} 下载完成"
    else
        echo "[start] 警告：mihomo 自动下载失败。代理桥暂不可用，可稍后手动放置 mihomo 二进制或设置 MIHOMO_PATH"
    fi
    chmod +x ./mihomo 2>/dev/null || true
fi

# ── 1. 首次运行：生成 .env ──
if [ ! -f .env ]; then
    cp .env.example .env
    echo "[start] 已从 .env.example 生成 .env —— 建议编辑 AUTH_TOKEN 后重启"
fi

# ── 2. 启动 ──
nohup ./zai2api > boot.log 2>&1 &
echo $! > zai2api.pid
sleep 2
if kill -0 "$(cat zai2api.pid)" 2>/dev/null; then
    echo "[start] zai2api 已启动 (PID $(cat zai2api.pid))"
    echo "[start] Dashboard: http://127.0.0.1:${PORT_DEFAULT}"
else
    echo "[start] 启动失败，请查看 boot.log"
    exit 1
fi
