#!/bin/bash
# Network Recon Script - Bonus 2
# Usage: bash recon.sh

clear
echo "====================================="
echo "  Bonus 2: Network Reconnaissance"
echo "====================================="
echo ""

# Step 1 - Our IP/MAC
echo "=== Step 1: Our Network Info ==="
echo "IP:    $(ifconfig en0 | grep 'inet ' | awk '{print $2}')"
echo "MAC:   $(ifconfig en0 | grep ether | awk '{print $2}')"
echo ""

# Step 2 - BetterCAP scan
echo "=== Step 2: Scanning LAN with BetterCAP ==="
bettercap -eval "net.probe on; sleep 5; net.show; quit" 2>/dev/null
echo ""

# Step 3 - Port scan only discovered devices (skip our IP)
echo "=== Step 3: Port Scan Discovered Devices ==="
echo ""

# Specific IPs found by BetterCAP in this LAN
TARGETS="192.168.1.1 192.168.1.2 192.168.1.6 192.168.1.10 192.168.1.11 192.168.1.13 192.168.1.16 192.168.1.18 192.168.1.43"

for ip in $TARGETS; do
  echo ">> $ip"
  PORTS=$(nmap -F $ip 2>/dev/null | grep "open" | awk '{print $1, $3}' | tr '\n' ', ')
  if [ -z "$PORTS" ]; then
    echo "   No open ports"
  else
    echo "   Ports: $PORTS"
  fi
  echo ""
done

echo "=== DONE ==="
