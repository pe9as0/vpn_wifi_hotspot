#📡 Hotspot VPN Router – README

This script creates a Wi‑Fi hotspot on Linux and routes all traffic through an already‑established VPN connection.
It is useful in mobile testing labs or as a VPN hotspot for TVs and other devices that have issues with VPN apps.

The script automatically:
- detects the active external interface (e.g., eth0, wlan0, tun0),
- configures the required iptables NAT rules,
- launches a Wi‑Fi hotspot on the second wireless interface (default: wlan1),
- routes all connected devices through the VPN.


#🔧 Requirements

Linux (Debian / Ubuntu / Kali)
A second Wi‑Fi interface (e.g., USB dongle)

###Installed:
- hostapd
- dnsmasq
- iptables
- any VPN client (GUI, OpenVPN, etc.)

#🔐 VPN Connection
You must establish the VPN before running the script.
You can use:

your VPN client GUI, or
OpenVPN:

'''sudo openvpn --config your_config.ovpn'''
To verify your external IP (before and after connecting VPN):
'''curl ifconfig.me'''
If your VPN creates a tunnel interface (e.g. OpenVPN/WireGuard), the script will automatically detect tun0 as the external WAN interface.

#🚀 How to Use

Plug in your second Wi‑Fi adapter (wlan1).
Start your VPN connection.
(Optional) Edit SSID/password in the script.
Run the script:

Shellsudo ./hotspot_vpn.shPokaż więcej wierszy

#📝 How the Script Works

Detects active WAN interface (eth0, wlan0, wwan0, tun0, etc.).
Flushes existing firewall rules.
Applies NAT/masquerade and forwarding rules.
Starts hostapd and dnsmasq.
Creates a Wi‑Fi network that routes traffic through the VPN IP.

#⚠️ Notes
This is very 'aplha version', just to proof it works as expected.
Designed for lab and testing environments.
Every device connected to this hotspot will appear online under your VPN’s public IP.
Requires root permissions.
