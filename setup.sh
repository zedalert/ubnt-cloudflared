#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

# Check for root permission
if [ $(id -u) != 0 ]; then
	echo 'Run with sudo'
	exit 1
fi

binary_repo='https://raw.githubusercontent.com/zedalert/ubnt-cloudflared/master'
origin_cert='https://support.cloudflare.com/hc/article_attachments/360037885371/origin_ca_rsa_root.pem'
scripts_dir='/config/scripts/cloudflared'
etc_dir='/etc/cloudflared'
opt_dir='/opt/cloudflared'
nat_rule=50
wan_rule=100
export scripts_dir nat_rule wan_rule

# Download all necessary files from github and cloudflare
function cloudflared_download {
	if [ $(findmnt -lnbo avail -t ubifs) -le 28000000 ]; then
		echo 'Not enough storage space available'
		return 1
	fi
	
	[ ! -f $scripts_dir ] && mkdir -p $scripts_dir
	
	! curl -f $origin_cert -o $scripts_dir/cert.pem && return 1
	! curl -f $binary_repo/config.yml -o $scripts_dir/config.yml && return 1
	! curl -f $binary_repo/setup.sh -o $scripts_dir/setup.sh && return 1
	
	# Detect processor bit width and byte order to get appropriate binary
	[ $(getconf LONG_BIT) = 64 ] && bit_width='64'
	[[ $(lscpu | grep -oP 'Byte Order:\s*\K.+') == 'Little Endian' ]] && byte_order='le'
	! curl -f $binary_repo/cloudflared-mips$bit_width$byte_order -o $scripts_dir/cloudflared && return 1
	
	chmod +x $scripts_dir/cloudflared
	chmod +x $scripts_dir/setup.sh

	return 0
}

# Place files in right places and install service
function cloudflared_install {
	[ ! -f $etc_dir ] && mkdir -p $etc_dir
	cp $scripts_dir/cert.pem $etc_dir
	cp $scripts_dir/config.yml $etc_dir
	
	[ ! -f $opt_dir ] && mkdir -p $opt_dir
	mv $scripts_dir/cloudflared $opt_dir
	
	! $opt_dir/cloudflared service install --legacy && return 1
	# No matter autoupdate is disabled in config, cloudflared will check for updates anyway
	systemctl disable cloudflared-update
	systemctl stop cloudflared-update.timer
	systemctl stop cloudflared-update
	
	return 0
}

# '0' keeps installation files, '1' removes cloudflared completely
function cloudflared_uninstall() {
	systemctl stop cloudflared
	$opt_dir/cloudflared service uninstall
	mv $opt_dir/cloudflared $scripts_dir
	rm -rf $etc_dir $opt_dir /var/log/cloudflared*
	
	$1 = 1 && rm -rf $scripts_dir
}

# Save partial config backup before installation
function configure_backup {
	show configuration commands >$scripts_dir/config-backup.tmp
	grep "firewall name WAN_OUT rule $wan_rule\|service dns forwarding options\|service nat rule $nat_rule\|system name-server" \
		$scripts_dir/config-backup.tmp >$scripts_dir/config-backup.txt
	
	# Detect LAN interface and local IP address
	lan_if=$(grep 'port-forward lan-interface' $scripts_dir/config-backup.tmp | grep -oP 'lan-interface\s*\K.+')
	lan_ip=$(grep "$lan_if address" $scripts_dir/config-backup.tmp | grep -Eo '([0-9]{1,3}[\.]){3}[0-9]{1,3}')
	rm $scripts_dir/config-backup.tmp
	export lan_if lan_ip
}

# Restore config backup after cloudflared removal
function configure_restore {
	configure
	
	delete firewall name WAN_OUT rule $wan_rule
	delete service dns forwarding options
	delete service nat rule $nat_rule
	delete system name-server
	
	while read line; do
		$line
	done <$scripts_dir/config-backup.txt
	
	commit ; save
	exit
}

# Configure necessary system settings for DNS to DoH translation
function configure_install {
	configure
	
	delete service dns forwarding options
	set service dns forwarding options 'server=127.0.0.1#5053'
	
	delete system name-server
	set system name-server 127.0.0.1
	
	delete service nat rule $nat_rule
	edit service nat rule $nat_rule
	set description 'Redirect insecure DNS requests'
	set destination address !$lan_ip
	set destination port 53
	set inbound-interface $lan_if
	set inside-address address $lan_ip
	set protocol tcp_udp
	set type destination
	exit
	
	delete firewall name WAN_OUT rule $wan_rule
	edit firewall name WAN_OUT rule $wan_rule
	set description 'Block insecure DNS requests'
	set action drop
	set protocol tcp_udp
	set destination port 53
	set log enable
	exit

	commit ; save
	exit
}

function ubnt_cloudflared_install() {
	if $1 = 1; then
		! cloudflared_download && return 1
	fi
	configure_backup
	configure_install
	
	# Rollback installation in case of error
	if [ ! cloudflared_install ]; then
		echo 'Installation failed, aborting'
		cloudflared_uninstall
		configure_restore
		return 1
	fi
	
	return 0
}

function ubnt_cloudflared_uninstall() {
	cloudflared_uninstall $1
	configure_restore
}

case $1 in
	'' )
		echo \
"Cloudflared script usage: $scripts_dir/setup.sh [option]
install	  download binary and config files, make backup, install service
enable	  install from downloaded files in case it was disabled before
disable	  remove service, restore system configuration from backup
remove	  same as disable but also removes binary, config files and backup

For more info please visit github.com/zedalert/ubnt-cloudflared"
	;;
	'install' )
		ubnt_cloudflared_install
	;;
	'enable' )
		ubnt_cloudflared_install 1
	;;
	'disable' )
		ubnt_cloudflared_uninstall
	;;
	'remove' )
		ubnt_cloudflared_uninstall 1
	;;
	* )
		echo 'Unknown command, launch without arguments to see options list'
	;;
esac
