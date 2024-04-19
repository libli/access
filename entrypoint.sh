#!/bin/bash

# 创建nginx使用ssl目录地址，会创建在挂载的宿主机上
mkdir -p /etc/pki/nginx/private/

$HOME/.acme.sh/acme.sh --register-account -m $ACME_Email

# 默认使用 DNSPod 进行域名验证
DNS_SERVICE="dns_dp"

# 检查环境变量是否传递，并且值为cloudflare
if [ "$DNS_PROVIDER" = "cloudflare" ]; then
    DNS_SERVICE="dns_cf"
fi

$HOME/.acme.sh/acme.sh --issue --dns $DNS_SERVICE -d $DP_Domain -d *.$DP_Domain

$HOME/.acme.sh/acme.sh --install-cert -d $DP_Domain \
--key-file       /etc/pki/nginx/private/$DP_Domain.key  \
--fullchain-file /etc/pki/nginx/$DP_Domain.crt \
--reloadcmd     "service nginx force-reload"

# 启动cron服务
service cron start

nginx -g "daemon off;"