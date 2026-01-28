# VPN + Wifi Hotspot setup  – README 📡

This script creates a Wi‑Fi hotspot on Linux and routes all traffic through an already‑established VPN connection.
It is useful in mobile testing labs where your access is for example vpn restricted or as a VPN hotspot for TVs and other devices that have issues with VPN apps.

The script automatically:
- detects the active external interface (e.g., eth0, wlan0, tun0),
- configures the required iptables NAT rules,
- launches a Wi‑Fi hotspot on the second wireless interface (default: wlan1),
- routes all connected devices through the VPN.


# Requirements 🔧 

Linux (tested on Debian / Ubuntu / Kali)
A second Wi‑Fi interface with AP mode supported (e.g., USB dongle)

### Installed:
- hostapd
- dnsmasq
- iptables
- any VPN client (GUI, OpenVPN, etc.)

# VPN Connection 🔐
You must establish the VPN before running the script.
You can use:
- your VPN client GUI, or
- OpenVPN:

```sudo openvpn --config your_config.ovpn```

To verify your external IP (before and after connecting VPN):

```curl ifconfig.me```

If your VPN creates a tunnel interface (e.g. OpenVPN/WireGuard), the script will automatically detect tun0 as the external WAN interface.

# How to Use 🚀

Plug in your second Wi‑Fi adapter (wlan1).
Start your VPN connection.
(Optional) Edit SSID/password in the script. SSID is hardcoded for now, password avaiable to set up. (I will change it in the future)
Run the script:
```sudo ./hotspot_vpn.sh```

# How the Script Works 📝

1. Detects active WAN interface (eth0, wlan0, wwan0, tun0, etc.).
2. Flushes existing firewall rules. (Flushes All rules - in future it will reenable previous rules :D)
3. Applies NAT/masquerade and forwarding rules.
4. Starts hostapd and dnsmasq.
5. Creates a Wi‑Fi network that routes traffic through the VPN IP.

# Notes ⚠️
**This is very 'aplha version', just to proof it works as expected.**

Designed for lab and testing environments.

Every device connected to this hotspot will appear online under your VPN’s public IP.

Requires root permissions.
