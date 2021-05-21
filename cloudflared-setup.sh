#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

# Pull files
mkdir -p /etc/cloudflared
mkdir -p /opt/cloudflared
if [ ! -f /etc/cloudflared/cert.pem ] || [ "$1" = "pull" ]; then
	/usr/bin/curl -sf https://developers.cloudflare.com/ssl/e2b9968022bf23b071d95229b5678452/origin_ca_rsa_root.pem --output /etc/cloudflared/cert.pem
fi
if [ ! -f /etc/cloudflared/config.yml ] || [ "$1" = "pull" ]; then
	/usr/bin/curl -sf https://raw.githubusercontent.com/zedalert/ubnt-cloudflared/master/config.yml --output /etc/cloudflared/config.yml
fi
if [ ! -f /opt/cloudflared/cloudflared ] || [ "$1" = "pull" ]; then
	sudo /usr/bin/curl -sf https://raw.githubusercontent.com/zedalert/ubnt-cloudflared/master/cloudflared-$2 --output /opt/cloudflared/cloudflared
fi
/bin/chmod +x /opt/cloudflared/cloudflared
/opt/cloudflared/cloudflared service install --legacy
/bin/systemctl disable cloudflared-update
/bin/systemctl stop cloudflared-update.timer
/bin/systemctl stop cloudflared-update
/bin/systemctl restart cloudflared

# System config 
configure

# Use local DNS proxy
delete service dns forwarding options
set service dns forwarding options "server=127.0.0.1#5053"
delete system name-server
set system name-server 127.0.0.1

# Redirect outgoing DNS packets to router (modify to match your's router IP address)
delete service nat rule 500

set service nat rule 500 description "Redirect insecure DNS requests"
set service nat rule 500 destination address !192.168.1.1
set service nat rule 500 destination port 53
set service nat rule 500 inbound-interface switch0
set service nat rule 500 inside-address address 192.168.1.1
set service nat rule 500 protocol tcp_udp
set service nat rule 500 type destination

# Block outgoing DNS packets and log them
delete firewall name WAN_OUT rule 1000

set firewall name WAN_OUT rule 1000 action drop
set firewall name WAN_OUT rule 1000 description "Block insecure DNS requests"
set firewall name WAN_OUT rule 1000 protocol tcp_udp
set firewall name WAN_OUT rule 1000 destination port 53
set firewall name WAN_OUT rule 1000 log enable

commit
save
exit
