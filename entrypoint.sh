#!/bin/bash

# 创建nginx使用ssl目录地址，会创建在挂载的宿主机上
mkdir -p /etc/pki/nginx/private/

# 需要先启动nginx, 否则acme.sh 跑 reloadcmd 时会失败。如果是第一次跑由于没cert会跑失败。
service nginx start

/root/.acme.sh/acme.sh --issue --dns dns_dp -d zaptiah.com -d *.zaptiah.com

/root/.acme.sh/acme.sh --install-cert -d zaptiah.com \
--key-file       /etc/pki/nginx/private/zaptiah.com.key  \
--fullchain-file /etc/pki/nginx/zaptiah.com.crt \
--reloadcmd     "service nginx force-reload"

# 再次启动一次，避免第一次启动nginx时没启动成功
service nginx start

# 通过下面命令确保 shell 不会跑完退出
tail -f /var/log/nginx/access.log