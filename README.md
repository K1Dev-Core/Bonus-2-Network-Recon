# Bonus 2 - Network Recon

> **Platform:** macOS (Apple Silicon / Intel)
> พัฒนาและทดสอบบน macOS เท่านั้น

ส่องหา IP/MAC Address เพื่อนบ้านใน LAN เดียวกัน + ส่อง Port ที่เปิด

## การติดตั้ง

```bash
# ติดตั้ง Homebrew (ถ้ายังไม่มี)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# ติดตั้ง BetterCAP
brew install bettercap

# ติดตั้ง nmap
brew install nmap
```

## วิธีใช้

```bash
cd Bonus-2-Network-Recon
bash recon.sh
```

รันครั้งเดียวได้ 3 ขั้นตอน:
1. แสดง IP/MAC ของเรา
2. BetterCAP scan หาอุปกรณ์ใน LAN (IP + MAC + Vendor)
3. nmap fast scan port เปิดของแต่ละ device
