#!/bin/sh

# Download and install V2Ray
mkdir /tmp/v2ray
curl -L -H "Cache-Control: no-cache" -o /tmp/v2ray/v2ray.zip https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
unzip /tmp/v2ray/v2ray.zip -d /tmp/v2ray
install -m 755 /tmp/v2ray/v2ray /usr/local/bin/v2ray
install -m 755 /tmp/v2ray/v2ctl /usr/local/bin/v2ctl

# Remove temporary directory
rm -rf /tmp/v2ray

mkdir /tmp/caddy
curl -L -H "Cache-Control: no-cache" -o /tmp/caddy/caddy.tar.gz --insecure https://github.com/caddyserver/caddy/releases/download/v1.0.3/caddy_v1.0.3_linux_amd64.tar.gz
tar -zxvf /tmp/caddy.tar.gz caddy
install -m 755 /tmp/caddy/caddy /usr/local/bin/caddy
mkdir /usr/local/wwwroot
wget -O /usr/share/wwwroot/index.html https://raw.githubusercontent.com/caddyserver/dist/master/welcome/index.html
rm -rf /tmp/caddy

install -d /usr/local/caddy
cat << EOF > /usr/local/caddy/Caddyfile
http://0.0.0.0:$PORT
{
	root /usr/share/wwwroot
	index index.html
	timeouts none
	proxy /v2rui 127.0.0.1:9090 {
		websocket
		header_upstream -Origin
	}
}
EOF

# V2Ray new configuration
install -d /usr/local/etc/v2ray
cat << EOF > /usr/local/etc/v2ray/config.json
{
    "inbounds": [
        {
            "port": 9090,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "alterId": 64
                    }
                ],
                "disableInsecureEncryption": true
            },
            "streamSettings": {
                "network": "ws"
		"security": "auto",	    
		}
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOF

# Run V2Ray
/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json
/usr/local/bin/caddy --conf=/usr/local/caddy/Caddyfile
