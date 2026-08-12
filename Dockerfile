# Z.AI2API — black-box release image (prebuilt binaries only, NO source build)
# 出厂镜像：直接拷入已编译好的 Linux 二进制运行，镜像构建过程不执行任何 go build，
# 发布包内亦不包含任何 .go 源码。
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      chromium ca-certificates curl tzdata \
    && rm -rf /var/lib/apt/lists/*

# chromedp 浏览器定位（设备令牌采集用）；mihomo 工作目录放持久化卷内
ENV CHROME_PATH=/usr/bin/chromium
ENV MIHOMO_DIR=/app/data/mihomo

WORKDIR /app
# 预编译黑盒二进制（由出厂打包流水线以 -trimpath -ldflags "-s -w" 构建）
COPY zai2api token-collector mihomo ./
RUN chmod +x /app/zai2api /app/token-collector /app/mihomo \
    && ln -sf /app/mihomo /usr/local/bin/mihomo \
    && /app/mihomo -v
COPY .env.example ./.env.example
COPY gateway.json.example ./gateway.json.example
# Render 不会像 docker-compose 那样挂载 .env,这里用默认配置落地一份;
# 运行时由 Render 环境变量(如 AUTH_TOKEN / ZAI_TOKEN / PORT)覆盖优先级更高的值。
COPY .env.example ./.env

# Runtime config/state lives in /app/data (mount a volume there)
VOLUME ["/app/data"]
EXPOSE 8088
ENTRYPOINT ["/app/zai2api"]
