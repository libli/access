# 网站接入层+SSL

特性：
1. nginx接入，多域名支持
2. 自动使用 acme.sh 申请证书及更新
3. 证书挂载到宿主机，重启 docker 时不用重新申请证书

使用前配置：
1. 修改 build.sh 中的 docker hub 地址，推送到自己的 docker hub 仓库
2. 修改 nginx 目录下的配置文件，修改域名
3. 修改 entrypoint/ssl.sh 中的域名
4. 修改 web 目录下的静态网站文件
5. 修改 DNS 域名指向服务器 IP

部署流程：
推送容器：`./build.sh docker_access_token`

在生产环境导入环境变量：
```
vi /etc/profile
# 在最底部加入
export DP_ID=******
export DP_KEY=******
```
使变更生效：`source /etc/profile`

运行容器，运行时会挂载acme.sh生成的证书文件目录以及安装到nginx的证书目录到宿主机。宿主机不用提前创建该目录，挂载时会自动创建。
```
docker run --name=zap -d --restart=unless-stopped -p 80:80 -p 443:443 \
  -v /root/ssl/nginx:/etc/pki/nginx \
  -v /root/ssl/acme/zaptiah.com:/root/.acme.sh/zaptiah.com_ecc \
  -e DP_Id=$DP_ID \
  -e DP_Key=$DP_KEY \
  libli/zap:0.1
```