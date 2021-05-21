#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

# Stop cloudflared and remove files
sudo /etc/systemctl stop cloudflared
sudo /opt/cloudflared/cloudflared service uninstall
sudo rm -rf /etc/cloudflared /opt/cloudflared /config/scripts/post-config.d/cloudflared-setup.sh /var/log/cloudflared*

# Reset default DNS config
configure
delete service dns forwarding options
delete system name-server
set system name-server 1.1.1.1
set system name-server 1.0.0.1
delete service nat rule 500
delete firewall name WAN_OUT rule 1000
commit
save
exit
