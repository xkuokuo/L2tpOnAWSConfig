#!/bin/bash

#install required packages
yum update
yum -y install rng-tools-5-7.12
yum -y install epel-release
yum -y install openswan-2.6.37-3.17
yum -y install xl2tpd-1.3.8-1

#start random number generator
service rngd start

#get local private ip
PRIVATE_IP=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)

#change ipsec.conf
IPSEC_CONF='/etc/ipsec.conf'
echo "
conn L2TP-PSK
    auto=add
    left=%defaultroute
    leftid=$PRIVATE_IP
    leftsourceip=$PRIVATE_IP
    leftnexthop=%defaultroute
    leftprotoport=17/%any
    rightprotoport=17/%any
    right=%any
    rightsubnet=vhost:%no,%priv
    forceencaps=yes
    authby=secret
    pfs=no
    type=transport
    auth=esp
    dpddelay=30
    dpdtimeout=120
    dpdaction=clear" >> $IPSEC_CONF

#config the secret
MY_SECRETE="zhuzhu"
IPSEC_SECRETE="my.secrets"
echo "%any %any : PSK $MY_SECRETE" >> "/etc/ipsec.d/$IPSEC_SECRETE"


#enable ip forwarding
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf

#disable redirects
for f in  /proc/sys/net/ipv4/conf/*/accept_redirects; do echo 0 > $f; done

for f in   /proc/sys/net/ipv4/conf/*/send_redirects; do echo 0 > $f; done

sysctl -p
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
service iptables save
service iptables restart

init 6
