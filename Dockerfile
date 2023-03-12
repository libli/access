FROM nginx:1.23
# 安装 cron，用于执行acme.sh自动更新证书的任务
RUN apt-get update && apt-get install -y cron
# 安装 acme.sh
RUN curl https://get.acme.sh | sh -s email=chris98276@gmail.com
# 开启自动升级
RUN /root/.acme.sh/acme.sh --upgrade --auto-upgrade
COPY entrypoint.sh /entrypoint.sh
# 把nginx目录下的所有配置文件复制到容器中的nginx配置下
COPY nginx /etc/nginx/conf.d/
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 80
EXPOSE 443