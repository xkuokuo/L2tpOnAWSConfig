#!/bin/bash

YELLOW='\033[0;33m'
NO_COLOR='\033[0m'

#install required packages
echo Install Requried Packages...
yum update
yum install -y --enablerepo=epel openswan xl2tpd 

#get local private ip
PRIVATE_IP=$(ifconfig eth0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
echo "Your local private IP is: $PRIVATE_IP"

#change ipsec.conf
IPSEC_CONF_FILE='/etc/ipsec.conf'
if ! grep -q 'conn L2TP-PSK' $IPSEC_CONF_FILE; then
  echo "Changing ipsec.conf ..."
  IPSEC_CONF="conn L2TP-PSK\n\tauto=add\n\tleft=%defaultroute\n\tleftid=$PRIVATE_IP\n\tleftsourceip=$PRIVATE_IP\n\tleftnexthop=%defaultroute\n\t"
  IPSEC_CONF+="leftprotoport=17/%any\n\trightprotoport=17/%any\n\tright=%any\n\trightsubnet=vhost:%no,%priv\n\tforceencaps=yes\n\tauthby=secret\n\t"\
  IPSEC_CONF+="pfs=no\n\ttype=transport\n\tauth=esp\n\tdpddelay=30\n\tdpdtimeout=120\n\tdpdaction=clear" >> $IPSEC_CONF_FILE
  echo -e $IPSEC_CONF >> $IPSEC_CONF_FILE
fi

#config the secret
echo -e "$YELLOW Please enter a shared secret (Remember it, would be used for VPN connection)$NO_COLOR":
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
echo -e "$YELLOW Please enter an account name for your VPN connection (Remember it, would be used for VPN connection)$NO_COLOR":
read CLIENT_NAME
echo -e "$YELLOW Please enter an password for your VPN connection (Remember it, would be used for VPN connection)$NO_COLOR":
read PASSWD

PASSWD_FILE=/etc/ppp/chap-secrets
echo "$CLIENT_NAME $SERVER_NAME $PASSWD *" >> $PASSWD_FILE

#restarting services
echo Restarting ipsec services...
service ipsec condrestart
echo Restarting xl2tpd services...
service xl2tpd condrestart

echo -e "$YELLOW All done. Enjoy =D$NO_COLOR"
