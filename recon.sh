#!/bin/bash
# Network Recon Script - Bonus 2
# Usage: bash recon.sh

clear
echo "  +------------------------------------------+"
echo "  |   Bonus 2: Network Reconnaissance        |"
echo "  +------------------------------------------+"
echo ""

# Step 1: Our info
MY_IP=$(ifconfig en0 | grep 'inet ' | awk '{print $2}')
MY_MAC=$(ifconfig en0 | grep ether | awk '{print $2}')
GW_IP=$(netstat -rn -f inet | grep default | awk '{print $2}')
echo "  My IP: $MY_IP"
echo "  My MAC: $MY_MAC"
echo "  Gateway: $GW_IP"
echo ""

# Step 2: Probe network (silent)
echo "  Probing LAN with BetterCAP..."
bettercap -eval "net.probe on; sleep 5; quit" 2>/dev/null >/dev/null
echo "  Done."
echo ""

# Step 3: Get live devices from ARP (only entries with real MAC, not incomplete)
echo "  Network Devices Found:"
echo ""
  echo "  +-----+-----------------+-------------------+--------------------------------------+------------------+"
  printf "  | %-3s | %-15s | %-17s | %-36s | %-16s |\n" "No." "IP Address" "MAC Address" "Device Type" "Open Ports"
  echo "  +-----+-----------------+-------------------+--------------------------------------+------------------+"

count=1
while IFS= read -r line; do
  # Extract IP
  ip=$(echo "$line" | sed -n 's/.*(\([0-9.]*\)).*/\1/p')
  # Extract MAC (skip if incomplete)
  mac=$(echo "$line" | grep -oE 'at [0-9a-fA-F:]{7,17}' | awk '{print $2}')
  # Skip broadcast and multicast
  [ "$mac" = "ff:ff:ff:ff:ff:ff" ] && continue
  [[ "$mac" == 1:0:5e:* ]] && continue
  [ -z "$mac" ] && continue

  # Pad MAC to full 17 chars (macOS shortens leading zeros)
  mac=$(echo "$mac" | awk -F: '{for(i=1;i<=NF;i++) printf "%02s%s", $i, (i<NF?":":"\n")}' | tr ' ' '0')

  # Lookup vendor from OUI (downloads IEEE list once, caches to ~/.cache/)
  OUI_CACHE="$HOME/.cache/oui.txt"
  if [ ! -f "$OUI_CACHE" ]; then
    mkdir -p "$HOME/.cache"
    curl -sL --max-time 120 -o "$OUI_CACHE" "https://standards-oui.ieee.org/oui/oui.txt"
  fi
  oui_prefix=$(echo "$mac" | cut -c1-8 | tr ':' '-' | tr '[:lower:]' '[:upper:]')
  vendor=$(grep -i "^$oui_prefix" "$OUI_CACHE" | sed 's/.*(hex)[[:space:]]*//' | head -1 | tr -d '\r')
  if [ -z "$vendor" ]; then
    byte=$(echo "$mac" | cut -d: -f1)
    if [ $((16#$byte & 2)) -eq 2 ]; then
      vendor="Private / Randomized MAC"
    else
      vendor="Unknown Device"
    fi
  fi
  # Try to resolve hostname for unknown/private devices
  hostname=""
  if [ "$vendor" = "Private / Randomized MAC" ] || [ "$vendor" = "Unknown Device" ]; then
    hostname=$(nslookup "$ip" 2>/dev/null | awk '/name =/ {print $NF}' | sed 's/\.$//')
    [ -z "$hostname" ] && hostname=$(dscacheutil -q host -a ip_address "$ip" 2>/dev/null | grep 'name:' | awk '{print $2}')
  fi

  # Build type string (truncate vendor first so markers fit)
  type="$vendor"
  [ -n "$hostname" ] && type="$hostname"
  type=$(echo "$type" | sed 's/  */ /g' | cut -c1-28 | sed 's/ *$//')
  [ "$ip" = "$GW_IP" ] && type="$type (GW)"
  [ "$ip" = "$MY_IP" ] && type="$type (เรา)"

  # Port scan (skip our own IP)
  if [ "$ip" = "$MY_IP" ]; then
    ports="-"
  else
    ports=$(nmap -F "$ip" 2>/dev/null | awk '/open/ {printf "%s ", $1}' | sed 's/\/tcp//g')
  fi
  [ -z "$ports" ] && ports="-"

  printf "  | %-3s | %-15s | %-17s | %-36s | %-16s |\n" "$count" "$ip" "$mac" "$type" "$ports"
  count=$((count+1))
done < <(arp -a)

echo "  +-----+-----------------+-------------------+--------------------------------------+------------------+"
echo "  Total: $((count-1)) device(s) in LAN (including ours)"
echo ""
