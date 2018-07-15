# L2tpOnAWSConfig
[English README](README_EN.md)
自动化部署脚本，在AWS Amazon Linux EC2 instance上安装/配置[Openswan](https://www.openswan.org/)，快速架设IPsec/L2TP VPN服务器。

## 使用方法

SSH登录运行Amazon Linux的AWS instance，在任意路径clone代码:

```
git clone https://github.com/xkuokuo/L2tpOnAWSConfig.git
```

直接运行vpnsetup（需要root权限）

```
sudo ./vpnsetup.sh
```

运行期间，脚本会分别提示输入shared secretes，account name，以及password：
```
...
Please enter a shared secret (Remember it, would be used for VPN connection):
your_shared_secret
...
Please enter an account name for your VPN connection (Remember it, would be used for VPN connection):
your_account_name
...
Please enter an password for your VPN connection (Remember it, would be used for VPN connection):
your_password
```

## 客户端连接
用之前输入的shared secret/account name/password，在客户端创建新的VPN连接（连接方式选择IPsec）。连接成功后，可通过访问网址ip.cn查看新的IP地址。

## FAQ
### 为什么是Amazon Linux？
因为我自己已经有一些东西部署在了Amazon Linux上，懒得挪了。。。

### 为什么选择L2TP？
目前OSX Sierra和iOS 10已经放弃对PPTP协议的支持，仅支持IPsec/L2TP，Cisco IPsec，和IPsec/IKEv2三种方式。L2TP方式相对较为稳定，且无需证书。

### 为什么选择Openswan而不是Strongswan？
因为Openswan的L2TP方式配置相对简单，且无需在客户端安装证书（尤其方便移动端设置）

### 将来是否会添加Ubuntu/RHEL等平台的支持？
看情况。。。

### 如果自己假设一台AWS一个月大概多少钱？
目前AWS最便宜的t2.micro一个月的价格约为十刀，完全足够包括视频在内的日常应用。


