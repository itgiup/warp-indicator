#!/bin/bash
set -e

APP_NAME="warp-indicator"
VERSION="1.0"
ARCH="all"
MAINTAINER="ITGiup <itgiup.com@gmail.com>"

# Build directory
BUILD_DIR="${APP_NAME}_${VERSION}"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR/DEBIAN
mkdir -p $BUILD_DIR/usr/local/bin
mkdir -p $BUILD_DIR/usr/share/applications
mkdir -p $BUILD_DIR/usr/share/doc/$APP_NAME

# Copy main script
cp warp-indicator.py $BUILD_DIR/usr/local/bin/$APP_NAME.py
chmod 755 $BUILD_DIR/usr/local/bin/$APP_NAME.py

# Desktop entry
cat > $BUILD_DIR/usr/share/applications/$APP_NAME.desktop <<EOF
[Desktop Entry]
Name=Warp Indicator
Comment=Show status and control Cloudflare WARP
Exec=/usr/bin/python3 /usr/local/bin/$APP_NAME.py
Icon=network-vpn
Terminal=false
Type=Application
Categories=Network;
X-GNOME-Autostart-enabled=true
EOF

# Debian control file
cat > $BUILD_DIR/DEBIAN/control <<EOF
Package: $APP_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Depends: python3, python3-gi, gir1.2-appindicator3-0.1, gir1.2-notify-0.7
Maintainer: $MAINTAINER
Description: A system tray indicator for Cloudflare WARP on Ubuntu (GNOME)
EOF

# License / copyright
cp LICENSE $BUILD_DIR/usr/share/doc/$APP_NAME/copyright

# Post-installation script (auto-install warp-cli)
cat > $BUILD_DIR/DEBIAN/postinst <<'EOF'
#!/bin/bash
set -e

echo ">>> Setting up Cloudflare WARP (warp-cli)..."

# Import Cloudflare GPG key
if [ ! -f /usr/share/keyrings/cloudflare-warp.gpg ]; then
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | tee /usr/share/keyrings/cloudflare-warp.gpg >/dev/null
fi

# Add Cloudflare repo if not exists
if [ ! -f /etc/apt/sources.list.d/cloudflare-client.list ]; then
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/cloudflare-client.list
fi

# Install warp-cli
apt-get update
apt-get install -y cloudflare-warp || true

echo ">>> Cloudflare WARP setup complete."
EOF

chmod 755 $BUILD_DIR/DEBIAN/postinst

# Post-remove script
cat > $BUILD_DIR/DEBIAN/postrm <<'EOF'
#!/bin/bash
set -e

echo ">>> Removing Warp Indicator..."

# Clean up desktop entry if still exists
rm -f /usr/share/applications/warp-indicator.desktop
rm -f /usr/local/bin/warp-indicator.py

echo ">>> Warp Indicator removed."

# If you also want to remove warp-cli when uninstalling, uncomment this line:
# apt-get remove --purge -y cloudflare-warp
EOF

chmod 755 $BUILD_DIR/DEBIAN/postrm

# Build .deb package
dpkg-deb --build $BUILD_DIR

echo "✅ Package built successfully: ${BUILD_DIR}.deb"
