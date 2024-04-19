# 网站接入层+SSL

使用场景描述，一般个人使用，会一个服务器上跑多个 http 协议的 docker，可能每个 docker 都要用不同的端口对外提供服务。如果想让这些 docker 都使用 https 协议，配置较麻烦。

通过本容器，可以解决通过不同的三级域名，以 https 协议标准的 443 端口，访问不同的 docker，如 alist, discuz, wordpress, Cloudreve等。

所有域名的 https 证书都是全自动更新的。新增一个容器只需要放一个 nginx config 文件即可。

有其它类似的镜像，比如 https://github.com/nginx-proxy/nginx-proxy 以及 https://github.com/Neilpang/letsproxy

但这些都太重了，依赖非常多。

特性：
1. nginx做接入层，提供反向代理，适合一个服务器配置多个域名
2. 全站 https，自动使用 acme.sh 申请证书及更新
3. 证书挂载到宿主机，重启 docker 时不用重新申请证书
4. 只支持一个域名，会申请该域名的二级证书及三级通配符证书
5. 只支持 DNSPod 上托管的域名，需要使用 DNSPod API 

## 使用方法
1. 获取 DNSPod API ID 和 KEY，[参考](https://support.dnspod.cn/Kb/showarticle/tsid/227/)
2. 在生产环境导入环境变量：
```
vi /etc/profile
# 在最底部加入
export DP_ID=******
export DP_KEY=******
# 要接入的域名，使用二级域名，如 mydomain.com，已经在 dnspod 中添加托管
export DP_DOMAIN=******
# 申请证书的邮箱，随便填一个自己的邮箱
export ACME_EMAIL=******
```

使变更生效：`source /etc/profile`

3. 创建容器网络，后面所有需要 nginx 反向代理的 docker 都放在这个网络中：
```
docker network create web_network
```

4. 运行容器，运行时会挂载 acme.sh 生成的证书文件目录以及安装到 nginx 的证书目录到宿主机。
```
docker run --name=access -d --restart=unless-stopped \
  --network=web_network \
  -p 80:80 -p 443:443 \
  -v /data/access/nginx-config:/etc/nginx/conf.d \
  -v /data/access/nginx-ssl:/etc/pki/nginx \
  -v /data/access/acme-ssl:/acmeconfig \
  -e DP_Id=$DP_ID \
  -e DP_Key=$DP_KEY \
  -e DP_Domain=$DP_DOMAIN \
  -e ACME_Email=$ACME_EMAIL \
  libli/access:latest
```

5. 配置两个默认的 nginx 反向代理文件：
```
vi /data/access/nginx-config/default.conf
# 内容如下
# 没在配置中的域名都不解析
server {
    listen       80 default_server;
    listen       [::]:80 default_server;
    server_name  _;
    return       444;
}

server {
    listen               443 ssl http2 default_server;
    listen               [::]:443 ssl http2 default_server;
    server_name          _;
    ssl_reject_handshake on;
}

# 重定向到 https
server {
    listen       80;
    listen       [::]:80;
    # 按这个顺序写性能较好，refer: http://nginx.org/en/docs/http/server_names.html
    server_name  mydomain.com www.mydomain.com *.mydomain.com;
    return       301 https://$host$request_uri;
}
```

```
vi /data/access/nginx-config/ssl.conf
# 内容如下
# 会放在http block，参考：https://docs.nginx.com/nginx/admin-guide/security-controls/terminating-ssl-http/
ssl_certificate             "/etc/pki/nginx/mydomain.com.crt";
ssl_certificate_key         "/etc/pki/nginx/private/mydomain.com.key";
ssl_session_cache           shared:SSL:1m;
ssl_session_timeout         10m;
ssl_ciphers                 HIGH:!aNULL:!MD5;
ssl_prefer_server_ciphers   on;

add_header Strict-Transport-Security "max-age=31536000;" always;
```

6. 运行需要反向代理的容器，比如运行一个 alist 容器，不需要使用-p把该容器的端口暴露到host：
```
docker run --name=alist -d --restart=unless-stopped \
  --network=web_network \
  -v /data/alist:/opt/alist/data \
  -e PUID=0 -e PGID=0 -e UMASK=022 \
  xhofe/alist:latest
```

7. 在 nginx 配置文件中配置 alist 的反向代理：
```
vi /data/access/nginx-config/alist.conf
# 内容如下
# alist
server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  alist.mydomain.com;

    location / {
        # 反向代理可以直接通过容器名访问，不需要使用 IP，ip 就是该容器内部暴露的端口
        proxy_pass       http://alist:5244;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Range $http_range;
        proxy_set_header If-Range $http_if_range;
        proxy_redirect   off;
        # 上传的最大文件尺寸
        client_max_body_size 20000m;
    }
}
```

8. 重启反向代理容器：
```
docker restart access
```

9. DNSPod 上添加 CNAME 记录，将 alist.mydomain.com 指向服务器 IP，

这样就可以通过https://alist.mydomain.com 访问 alist 了。以后有新的容器，如wordpress, discuz等，只需要在 nginx 配置文件中配置反向代理，然后重启反向代理容器即可。

### 支持cloudflare
1. 获取global api key: https://dash.cloudflare.com/profile/api-tokens
2. 运行容器：
```bash
docker run --name=access -d --restart=unless-stopped \
--network=web_network \
-p 80:80 -p 443:443 \
-v /data/access/nginx-config:/etc/nginx/conf.d \
-v /data/access/nginx-ssl:/etc/pki/nginx \
-v /data/access/acme-ssl:/acmeconfig \
-e DNS_PROVIDER=cloudflare \
-e CF_Key=$CF_KEY \
-e CF_Email=$CF_EMAIL \
-e DP_Domain=$DP_DOMAIN \
-e ACME_Email=$ACME_EMAIL \
libli/access:latest
```