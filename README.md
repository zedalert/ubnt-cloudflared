# ubnt-cloudflared
Install Cloudflare's DNS-over-HTTPS proxy on UniFi gateways and EdgeMax routers. This setup will survive reboots and re-provisions.

Only working for IPv4 at the moment.

Increase privacy on your network and prevent your ISP to eavesdrop your DNS requests to build your internet browsing history !

## Hardware
### Tested
* UniFi Security Gateway 3P
* EdgeRouter X/X-SFP

### Should work on (but not tested)
* All EdgeRouter models
* All UniFi Security Gateway models

## Guide
### Installing easy way (not secure)
In a ssh session run the following command :
```sh
sudo bash <(curl -s https://raw.githubusercontent.com/zedalert/ubnt-cloudflared/master/setup.sh) install
```

### Installing hard way (secure)
Download official [cloudflared](https://github.com/cloudflare/cloudflared/) client source code from GitHub.

Build it with Go and target platform - `mipsle`, `mips64`, etc. depending on SoC used in your device. You can get all necessary information by typing these commands in terminal:
```sh
getconf LONG_BIT
lscpu | grep 'Byte Order'
```

Place resulting binary into `/opt/cloudflared/` directory and install it as service with `--legacy` switch to bypass use of Argo Tunnel.
Addationally you can compress binary with [upx](https://github.com/upx/upx/) to save extra space.

### Maintenance
During installation process partial config backup is created. You can disable cloudflared service at any time by just simply typing in root shell:
```sh
/config/scripts/cloudflared/setup.sh disable
```
After that all settings will be restored to original ones before installation, at the same time all installation files and binary are keept in `/config/scripts/cloudflared` directory (considering you didn't remove these files). So at any time you can enable service again by typing:
```sh
/config/scripts/cloudflared/setup.sh enable
```

### Updating
Just run the install script again ;)

### Uninstall
In a root ssh session run the following command :
```sh
/config/scripts/cloudflared/setup.sh remove
```

## Contributing
* Please fork and submit PR's if you have any improvements.
* Implementing IPv6 features would help greatly.
* Feel free to submit issues !
* Testing this on hardware I did not test yet would be wonderful !

## Credits
* https://developers.cloudflare.com/1.1.1.1/dns-over-https/cloudflared-proxy/
* https://github.com/cloudflare/cloudflared/issues/251
* https://github.com/yon2004/ubnt_cloudflared
* https://bendews.com/posts/implement-dns-over-https/
* https://zyfdegh.github.io/post/202002-go-compile-for-mips/
* https://community.ui.com/questions/Scripts-on-USG/551ede69-de7c-4fa2-9dbe-5e7921406255
* https://community.ui.com/questions/Deploying-USG-scripts-through-controller/d6e7457a-6dc8-4146-96bd-fecaff27f785
* https://community.ui.com/questions/Options-for-running-DNS-over-HTTPS-on-EdgeMax-device/065119c7-1f5c-4c29-8bc2-e8a0217bc018#answer/1b2861f6-e106-461e-af79-da9303a38e61
