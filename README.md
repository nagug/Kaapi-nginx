# Kaapi-nginx (Only For Debian)
Modified & customised version of [Angristan nginx-autoinstall](https://github.com/Angristan/nginx-autoinstall) created for purpose of building personal servers. All orginal credits to Angristan. Focus here is only security modules. If any suggestions add some more secure modules. Please let me know.

## Key Features
- All the latest version stable code
- removed some modules from original script
- All included nginx.config 
- LibreSSL
- ngx_pagespeed
- ngx_brotli
- ngx_headers_more
- Naxsi WAF 
- Cloudflare's TLS Dynamic Records Resizing patch

## Tested On
- Only on Debian 9 (May work on Debian 8)


## Installation
Just download and execute the script :
```
wget https://raw.githubusercontent.com/nagug/Kaapi-nginx/master/nginxbuilder.sh
chmod +x nginxbuilder.sh
./nginx-autoinstall.sh
```
## Note on Naxsi
Enable inside your http block of the server for naxsi.:

```
include /tmp/naxsi_ut/naxsi_core.rules;
```
More details on naxsi configuration is available in [Naxsi Wiki](https://github.com/nbs-system/naxsi/wiki)

## For updates
Change the versions approriately in the script and run again 

## Future work (no Commitments here)
- May include options
- May integrate security modules 

## Logs files (Same as original script)
There are two logs files created when running the script.

- `/tmp/nginx-autoinstall-output.log`
- `/tmp/nginx-autoinstall-error.log` (use this one for debugging)

## LICENSE

GPL v3.0