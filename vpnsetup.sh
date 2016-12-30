#!/bin/bash

#install required packages
echo Install Requried Packages...
yum update
yum install -y --enablerepo=epel openswan xl2tpd 

#get local private ip
PRIVATE_IP=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
echo Your local private IP is: $PRIVATE_IP 

#change ipsec.conf
echo Changing ipsec.conf ...
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
echo Please enter a shared secret (Remember it, would be used for VPN connection):
read MY_SECRETE
IPSEC_SECRETE="/etc/ipsec.secrets"
echo "%any %any : PSK \"$MY_SECRETE\"" >> $IPSEC_SECRETE

#enable ip forwarding
echo Enable IP forwarding...
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/' /etc/sysctl.conf

#disable redirects
echo Disable IMCP redirects... 
for f in  /proc/sys/net/ipv4/conf/*/accept_redirects; do echo 0 > $f; done

for f in   /proc/sys/net/ipv4/conf/*/send_redirects; do echo 0 > $f; done

sysctl -p

echo Restart IP tables 
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
service iptables save
service iptables restart


#xl2tpd conf setup
echo set xl2tp configuration
XL2TPD_CONF=/etc/xl2tpd/xl2tpd.conf
SERVER_NAME=MY_VPN_SERVER
sed -ir "s/require chap = no/require chap = yes/" $XL2TPD_CONF
sed -ir "s/name = .*/name = $SERVER_NAME/" $XL2TPD_CONF

#xl2tpd password setup
echo Please enter an account name for your VPN connection (Remember it, would be used for VPN connection):
read CLIENT_NAME
echo Please enter an password for your VPN connection (Remember it, would be used for VPN connection):
read PASSWD

PASSWD_FILE=/etc/ppp/chap-secrets
echo "$CLIENT_NAME $SERVER_NAME $PASSWD *" >> $PASSWD_FILE

#restarting services
echo Restarting ipsec services...
service ipsec restart
echo Restarting xl2tpd services...
service xl2tpd restart

echo All done. Enjoy =D
