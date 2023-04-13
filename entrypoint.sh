#!/bin/bash

# 创建nginx使用ssl目录地址，会创建在挂载的宿主机上
mkdir -p /etc/pki/nginx/private/

$HOME/.acme.sh/acme.sh --register-account -m $ACME_Email

$HOME/.acme.sh/acme.sh --issue --dns dns_dp -d $DP_Domain -d *.$DP_Domain

$HOME/.acme.sh/acme.sh --install-cert -d $DP_Domain \
--key-file       /etc/pki/nginx/private/$DP_Domain.key  \
--fullchain-file /etc/pki/nginx/$DP_Domain.crt \
--reloadcmd     "service nginx force-reload"

nginx -g "daemon off;"