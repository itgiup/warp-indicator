# Warp Indicator

A simple system tray indicator for **Cloudflare WARP (warp-cli)** on Ubuntu (GNOME).  
It shows WARP connection status, allows you to connect/disconnect with one click,  
and will automatically reconnect if the connection drops.

![screenshot](docs/screenshot.png)

---

## ✨ Features
- Tray icon in the top panel (AppIndicator).
- Menu options:
  - ✅ Connect WARP
  - ✅ Disconnect WARP
  - ✅ Quit
- Auto-reconnect if disconnected.
- Desktop notifications on connect/disconnect.
- Works with Ubuntu 22.04 / 24.04 (GNOME).

---

## 📦 Installation

### Option 1: Install `.deb` package
Download the latest `.deb` from [Releases](https://github.com/itgiup/warp-indicator/releases) and install:

```bash
sudo dpkg -i warp-indicator_1.0.deb
sudo apt-get -f install
```

The package will:
- Install `warp-indicator` (the tray app).
- Automatically install **Cloudflare WARP (warp-cli)** if not already installed.

---

### Option 2: Run from source
Install dependencies:

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-gi gir1.2-appindicator3-0.1 gir1.2-notify-0.7
```

Clone this repo and run:

```bash
git clone https://github.com/itgiup/warp-indicator.git
cd warp-indicator
chmod +x warp-indicator.py
./warp-indicator.py
```

---

## 🔧 Development

### Build `.deb` package
```bash
chmod +x build-deb.sh
./build-deb.sh
```

This generates `warp-indicator_1.0.deb`.

---

## 📜 License
[MIT License](LICENSE)  
Copyright (c) 2025 ITGiup <itgiup.com@gmail.com>

You are free to use, modify, and distribute this software for both personal and commercial purposes.
