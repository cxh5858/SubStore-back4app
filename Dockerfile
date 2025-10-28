FROM node:lts-alpine

WORKDIR /opt/app

# 安装工具
RUN apk add --no-cache curl tzdata unzip

# 设置时区
ENV TIME_ZONE=Asia/Shanghai 
RUN cp /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone

# 下载 Sub-Store 后端和前端
ADD https://github.com/sub-store-org/Sub-Store/releases/latest/download/sub-store.bundle.js /opt/app/sub-store.bundle.js
ADD https://github.com/sub-store-org/Sub-Store-Front-End/releases/latest/download/dist.zip /opt/app/dist.zip
RUN unzip dist.zip && mv dist frontend && rm dist.zip

# 下载 http-meta
ADD https://github.com/xream/http-meta/releases/latest/download/http-meta.bundle.js /opt/app/http-meta.bundle.js
ADD https://github.com/xream/http-meta/releases/latest/download/tpl.yaml /opt/app/http-meta/tpl.yaml

# 下载 mihomo 二进制
RUN set -eux; \
    version=$(curl -sL --connect-timeout 5 --max-time 10 --retry 2 'https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt'); \
    arch=$(arch | sed s/aarch64/arm64/ | sed s/x86_64/amd64-compatible/); \
    url="https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/mihomo-linux-$arch-$version.gz"; \
    curl -sL "$url" -o /opt/app/http-meta/mihomo.gz; \
    gunzip /opt/app/http-meta/mihomo.gz; \
    chmod +x /opt/app/http-meta/mihomo

RUN chmod -R 755 /opt/app

# 暴露端口（Back4App 必须要有）
EXPOSE 3001

# 启动命令
CMD mkdir -p /opt/app/data && cd /opt/app/data && \
  META_FOLDER=/opt/app/http-meta HOST=0.0.0.0 node /opt/app/http-meta.bundle.js > /opt/app/data/http-meta.log 2>&1 & \
  echo "HTTP-META started..." && \
  SUB_STORE_BACKEND_API_HOST=0.0.0.0 \
  SUB_STORE_FRONTEND_HOST=0.0.0.0 \
  SUB_STORE_FRONTEND_PORT=3001 \
  SUB_STORE_FRONTEND_PATH=/opt/app/frontend \
  SUB_STORE_DATA_BASE_PATH=/opt/app/data \
  node /opt/app/sub-store.bundle.js
