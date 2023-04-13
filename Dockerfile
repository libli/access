FROM nginx:1.23.4-bullseye
# 安装 cron，用于执行acme.sh自动更新证书的任务
RUN apt-get update && apt-get install -y \
    cron \
    ca-certificates \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/*

ENV TZ=Asia/Shanghai
# 安装 acme.sh
ENV AUTO_UPGRADE=1
ENV LE_CONFIG_HOME=/acmeconfig
RUN curl https://get.acme.sh | sh
VOLUME ["/acmeconfig"]

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 80
EXPOSE 443