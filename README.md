# ubnt-cloudflared
Install Cloudflare's DNS proxy on UniFi gateways and EdgeMax routers. This setup will survive reboots and re-provisions.

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
### Installing hard way (secure)
Download official [cloudflared](https://github.com/cloudflare/cloudflared/) client from GitHub.

Build it with Go and target platform - `mips`, `mipsle` or `mips64`, depending on your router model. You can get all necessary information by using these commands:
```sh
getconf LONG_BIT
lscpu | grep 'Byte Order'
```

Place resulting binary into `/opt/cloudflared/` directory and install it as service with `--legacy` switch to bypass use of Argo Tunnel.

### Installing easy way (not secure)
In a ssh session run the following command :
```sh
bash <(curl -s https://raw.githubusercontent.com/zedalert/ubnt-cloudflared/master/install.sh)
```

### Updating
Just run the install script again ;)

### Uninstall
In a ssh session run the following command :
```sh
bash <(curl -s https://raw.githubusercontent.com/zedalert/ubnt-cloudflared/master/uninstall.sh)
```

## Contributing
* Please fork and submit PR's if you have any improvements.
* Implementing IPv6 features would help greatly.
* Feel free to submit issues !
* Testing this on hardware I did not test yet would be wonderful !

## Credits
* https://bendews.com/posts/implement-dns-over-https/
* https://developers.cloudflare.com/1.1.1.1/dns-over-https/cloudflared-proxy/
* https://github.com/yon2004/ubnt_cloudflared
* https://community.ubnt.com/t5/UniFi-Routing-Switching/Scripts-on-USG/td-p/1402210
* https://community.ubnt.com/t5/UniFi-Routing-Switching/Deploying-USG-scripts-through-controller/td-p/2140097
* https://github.com/cloudflare/cloudflared/issues/251
* https://community.ui.com/questions/Options-for-running-DNS-over-HTTPS-on-EdgeMax-device/065119c7-1f5c-4c29-8bc2-e8a0217bc018#answer/1b2861f6-e106-461e-af79-da9303a38e61
* https://zyfdegh.github.io/post/202002-go-compile-for-mips/
