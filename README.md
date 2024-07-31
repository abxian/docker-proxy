> docker下使用nginx反代dockerhub进行国内镜像加速

# 说明

国内docker镜像已经被gfw封锁，所以使用境外服务器来加速dockerhub镜像


# 服务器配置 
1. 拉取文件
```
git clone https://github.com/abxian/docker-proxy.git && cd docker-proxy

```
2. 填入域名和申请cerbot ssl的邮箱

```
nano .env

```

3. 执行
```
docker-compose up --build -d

```


# 客户端配置

1. linux: 修改 /etc/docker/daemon.json
```
{
"registry-mirrors": ["域名"]
}

```

或者  
```
sudo tee /etc/docker/daemon.json <<EOF
{
"registry-mirrors": ["改成你的域名"]
}
EOF

```
重启docker服务
```
sudo systemctl daemon-reload
sudo systemctl restart docker

```
拉取docker镜像测试配置是否生效
```
docker run hello-world

```
