#!/bin/bash

set -e

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'

REQUIRED_CMDS=("hostapd" "dnsmasq" "iptables" "ip" "iw")

echo -e "${GREEN}[1/6] Sprawdzanie wymaganych pakietów...${NC}"
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Brakuje: $cmd${NC}"
        echo "Zainstaluj go: sudo apt install $cmd"
        exit 1
    fi
done
echo -e "${GREEN}✓ Wszystkie wymagane pakiety są zainstalowane.${NC}"

echo -e "${GREEN}[2/6] Wykrywanie interfejsu z dostępem do internetu...${NC}"

if ip route | grep -q "^0.0.0.0/1 .* dev tun0" && ip route | grep -q "^128.0.0.0/1 .* dev tun0"; then
    EXTERNAL_IF="tun0"
    echo -e "${GREEN}✓ Wykryto pełne tunelowanie przez VPN: $EXTERNAL_IF${NC}"
else
    EXTERNAL_IF=$(ip route | grep default | awk '{print $5}' | head -n 1)
    echo -e "${GREEN}✓ Używam domyślnego interfejsu: $EXTERNAL_IF${NC}"
fi

read -p "Podaj hasło do hotspotu Wi-Fi (min 8 znaków): " WIFI_PASS
if [ ${#WIFI_PASS} -lt 8 ]; then
    echo -e "${RED}Hasło musi mieć co najmniej 8 znaków.${NC}"
    exit 1
fi

HOTSPOT_IF="wlan1"
HOTSPOT_SSID="SoHotSpot"
HOTSPOT_IP="10.10.0.1"
DHCP_RANGE_START="10.10.0.10"
DHCP_RANGE_END="10.10.0.100"

# 🔄 Czyścimy wcześniejsze instancje / do przerobienia w przyszłości na lepiej ukierunkowany kill!
sudo pkill dnsmasq || true
sudo pkill hostapd || true

echo -e "${GREEN}[3/6] Sprawdzanie trybu AP i tworzenie konfiguracji...${NC}"

# hostapd.conf
cat <<EOF | sudo tee /etc/hostapd/hostapd.conf > /dev/null
interface=$HOTSPOT_IF
driver=nl80211
ssid=$HOTSPOT_SSID
hw_mode=g
channel=9
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$WIFI_PASS
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

# dnsmasq.conf
cat <<EOF | sudo tee /etc/dnsmasq.d/hotspot.conf > /dev/null
interface=$HOTSPOT_IF
dhcp-range=$DHCP_RANGE_START,$DHCP_RANGE_END,255.255.255.0,24h
EOF

echo -e "${GREEN}[4/6] Konfiguracja interfejsu hotspotu...${NC}"
sudo nmcli dev set $HOTSPOT_IF managed no
sleep 2
sudo ip link set $HOTSPOT_IF up
sudo ip addr flush dev $HOTSPOT_IF || true
sudo ip addr add $HOTSPOT_IP/24 dev $HOTSPOT_IF

echo -e "${GREEN}[5/6] Uruchamianie dnsmasq i hostapd...${NC}"
sudo dnsmasq --no-daemon --conf-file=/etc/dnsmasq.d/hotspot.conf &
DNSMASQ_PID=$!

sleep 1
sudo hostapd /etc/hostapd/hostapd.conf &
HOSTAPD_PID=$!

# Trap -  czyszczenie
trap "echo -e '\n${ORANGE}Zatrzymywanie hotspotu...${NC}'; sudo kill $DNSMASQ_PID; sudo kill $HOSTAPD_PID; sudo iptables -F; sudo iptables -t nat -F; exit 0" SIGINT

sleep 2

echo -e "${GREEN}[6/6] Konfiguracja iptables i NAT...${NC}"
sudo iptables -A FORWARD -i $HOTSPOT_IF -o $EXTERNAL_IF -j ACCEPT
sudo iptables -A FORWARD -i $EXTERNAL_IF -o $HOTSPOT_IF -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o $EXTERNAL_IF -j MASQUERADE

echo -e "${GREEN}✓ Hotspot gotowy!${NC}"
echo -e "SSID: ${RED}${HOTSPOT_SSID}${NC}"
echo -e "Hasło: ${ORANGE}${WIFI_PASS}${NC}"
echo -e "Podłącz się do sieci Wi-Fi i powinieneś mieć dostęp do internetu."

# Pozostaw procesy aktywne, aż użytkownik przerwie / żeby było wydać czy coś nie padło w międzyczasie
wait
