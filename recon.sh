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
echo "  My IP: $MY_IP"
echo "  My MAC: $MY_MAC"
echo ""

# Step 2: Probe network (silent)
echo "  Probing LAN with BetterCAP..."
bettercap -eval "net.probe on; sleep 5; quit" 2>/dev/null >/dev/null
echo "  Done."
echo ""

# Step 3: Get live devices from ARP (only entries with real MAC, not incomplete)
echo "  Network Devices Found:"
echo ""
echo "  +-----+-----------------+-------------------+----------------------+------------------+"
printf "  | %-3s | %-15s | %-17s | %-20s | %-16s |\n" "No." "IP Address" "MAC Address" "Device Type" "Open Ports"
echo "  +-----+-----------------+-------------------+----------------------+------------------+"

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

  # Guess device type from MAC
  mac_prefix=$(echo "$mac" | cut -c1-8 | tr '[:upper:]' '[:lower:]')
  case "$mac_prefix" in
    90:55:de) type="Router (Fiberhome)"   ;;
    08:cc:81) type="IP Camera (Hikvision)" ;;
    34:2e:b7) type="PC (Intel)"           ;;
    32:e5:ca) type="iPad 5"               ;;
    c0:b0:d1) type="MacBook Pro (เรา)"    ;;
    *)        type="Unknown Device"       ;;
  esac

  # Port scan (skip our own IP)
  if [ "$ip" = "$MY_IP" ]; then
    ports="-"
  else
    ports=$(nmap -F "$ip" 2>/dev/null | awk '/open/ {printf "%s ", $1}' | sed 's/\/tcp//g')
  fi
  [ -z "$ports" ] && ports="-"

  printf "  | %-3s | %-15s | %-17s | %-20s | %-16s |\n" "$count" "$ip" "$mac" "$type" "$ports"
  count=$((count+1))
done < <(arp -a)

echo "  +-----+-----------------+-------------------+----------------------+------------------+"
echo "  Total: $((count-1)) device(s) in LAN (including ours)"
echo ""
