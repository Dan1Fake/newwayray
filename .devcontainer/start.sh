#!/bin/bash

# ─────────────────────────────────────────────
#  newwayray  –  dynamic multi-config starter
# ─────────────────────────────────────────────

# Generate a unique UUID per inbound (uses kernel random UUID source)
gen_uuid() { cat /proc/sys/kernel/random/uuid; }
UUID1=$(gen_uuid)   # VLESS xHTTP packet-up  (port 443)
UUID2=$(gen_uuid)   # VLESS xHTTP stream-up  (port 8080)
UUID3=$(gen_uuid)   # VLESS WebSocket        (port 8880)
UUID4=$(gen_uuid)   # VMess WebSocket        (port 9090)
UUID5=$(gen_uuid)   # VLESS gRPC             (port 9443)
UUID6=$(gen_uuid)   # Trojan WebSocket       (port 7777)

# Target IPs — 10 IPs (previous 5 + 5 new)
IP1="63.141.252.203"
IP2="50.7.5.83"
IP3="94.130.50.12"
IP4="50.7.87.4"
IP5="144.76.1.88"
IP6="85.10.207.48"
IP7="95.216.69.37"
IP8="94.130.13.19"
IP9="94.130.33.41"
IP10="204.12.196.34"

# ── write the xray config with ALL inbounds ──────────────────────────────────
cat > /etc/config.json << EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${UUID1}", "flow": "" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "mode": "packet-up",
          "path": "/xhttp-pu"
        }
      }
    },
    {
      "port": 8080,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${UUID2}" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "none",
        "xhttpSettings": {
          "mode": "stream-up",
          "path": "/xhttp-su"
        }
      }
    },
    {
      "port": 8880,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${UUID3}" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/ws"
        }
      }
    },
    {
      "port": 9090,
      "protocol": "vmess",
      "settings": {
        "clients": [
          { "id": "${UUID4}", "alterId": 0 }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/vmess-ws"
        }
      }
    },
    {
      "port": 9443,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "${UUID5}" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "security": "none",
        "grpcSettings": {
          "serviceName": "grpc"
        }
      }
    },
    {
      "port": 7777,
      "protocol": "trojan",
      "settings": {
        "clients": [
          { "password": "${UUID6}" }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/trojan-ws"
        }
      },
      "tag": "trojan-ws"
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" }
  ]
}
EOF

# ── make all ports public via GitHub CLI ─────────────────────────────────────
gh codespace ports visibility \
  443:public 8080:public 8880:public 9090:public 9443:public 7777:public \
  -c "$CODESPACE_NAME" 2>/dev/null || true

# ── Codespace SNI/host domains (TLS termination is done by GitHub's proxy) ───
H443="${CODESPACE_NAME}-443.app.github.dev"
H8080="${CODESPACE_NAME}-8080.app.github.dev"
H8880="${CODESPACE_NAME}-8880.app.github.dev"
H9090="${CODESPACE_NAME}-9090.app.github.dev"
H9443="${CODESPACE_NAME}-9443.app.github.dev"
H7777="${CODESPACE_NAME}-7777.app.github.dev"

# ── helper: print 10 links (one per IP) for a given config ────────────────────
print_links() {
  local label="$1"
  local link_template="$2"   # must contain __IP__ as placeholder
  for IP in "$IP1" "$IP2" "$IP3" "$IP4" "$IP5" "$IP6" "$IP7" "$IP8" "$IP9" "$IP10"; do
    echo "${link_template//__IP__/$IP}"
  done
}

# ── build VMess base64 for each IP ───────────────────────────────────────────
vmess_link() {
  local IP="$1"
  local JSON
  JSON=$(printf '{"v":"2","ps":"VMess-WS","add":"%s","port":"443","id":"%s","aid":"0","scy":"none","net":"ws","type":"none","host":"%s","path":"/vmess-ws","tls":"tls","sni":"%s","alpn":""}' \
    "$IP" "$UUID4" "$H9090" "$H9090")
  echo "vmess://$(echo -n "$JSON" | base64 -w 0)"
}

# ── print everything ──────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   🚀  newwayray  –  your V2Ray / Xray links"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

print_links "VLESS-xHTTP-PacketUp" \
  "vless://${UUID1}@__IP__:443?encryption=none&security=tls&sni=${H443}&host=${H443}&type=xhttp&path=%2Fxhttp-pu&mode=packet-up#VLESS-xHTTP-PacketUp"
echo ""

print_links "VLESS-xHTTP-StreamUp" \
  "vless://${UUID2}@__IP__:443?encryption=none&security=tls&sni=${H8080}&host=${H8080}&type=xhttp&path=%2Fxhttp-su&mode=stream-up#VLESS-xHTTP-StreamUp"
echo ""

print_links "VLESS-WS" \
  "vless://${UUID3}@__IP__:443?encryption=none&security=tls&sni=${H8880}&host=${H8880}&type=ws&path=%2Fws#VLESS-WebSocket"
echo ""

for IP in "$IP1" "$IP2" "$IP3" "$IP4" "$IP5" "$IP6" "$IP7" "$IP8" "$IP9" "$IP10"; do
  echo "$(vmess_link "$IP")"
done
echo ""

print_links "VLESS-gRPC" \
  "vless://${UUID5}@__IP__:443?encryption=none&security=tls&sni=${H9443}&host=${H9443}&type=grpc&serviceName=grpc#VLESS-gRPC"
echo ""

print_links "Trojan-WS" \
  "trojan://${UUID6}@__IP__:443?security=tls&sni=${H7777}&host=${H7777}&type=ws&path=%2Ftrojan-ws#Trojan-WS"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Each config has its own unique UUID (randomized at startup)"
echo "  TLS SNI/host : provided by GitHub (*.app.github.dev)"
echo "  Tip: if one IP is blocked by your ISP, try another"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── hand off to xray (keeps the container alive) ─────────────────────────────
exec /usr/local/bin/xray -c /etc/config.json
