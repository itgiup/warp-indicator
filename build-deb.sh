#!/bin/bash
set -euo pipefail

PKGNAME="warp-indicator"
VERSION="1.0"
ARCH="all"
MAINTAINER="ITGiup <itgiup.com@gmail.com>"
BUILD_DIR="/tmp/${PKGNAME}_${VERSION}"

echo ">>> Cleaning old build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/local/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/etc/xdg/autostart"
mkdir -p "$BUILD_DIR/usr/share/doc/$PKGNAME"
mkdir -p "$BUILD_DIR/usr/share/icons/warp-indicator"

# Copy Python app
install -m 755 warp-indicator.py "$BUILD_DIR/usr/local/bin/warp-indicator"

# Copy icons
install -m 644 ./logo.dark.svg "$BUILD_DIR/usr/share/icons/warp-indicator/logo.dark.svg"
install -m 644 ./logo.light.svg "$BUILD_DIR/usr/share/icons/warp-indicator/logo.light.svg"

# Desktop entry for menu
cat > "$BUILD_DIR/usr/share/applications/$PKGNAME.desktop" <<'EOF'
[Desktop Entry]
Name=Warp Indicator
Comment=Show status and control Cloudflare WARP
Exec=/usr/local/bin/warp-indicator
Icon=/usr/share/icons/warp-indicator/logo.light.svg
Terminal=false
Type=Application
Categories=Network;
EOF

# Desktop entry for autostart
cat > "$BUILD_DIR/etc/xdg/autostart/$PKGNAME.desktop" <<'EOF'
[Desktop Entry]
Name=Warp Indicator
Comment=Auto start Warp Indicator
Exec=/usr/local/bin/warp-indicator
Icon=/usr/share/icons/warp-indicator/logo.light.svg
Terminal=false
Type=Application
X-GNOME-Autostart-enabled=true
Categories=Network;
EOF

# Debian control file
cat > "$BUILD_DIR/DEBIAN/control" <<EOF
Package: $PKGNAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Depends: python3, python3-gi, gir1.2-appindicator3-0.1, gir1.2-notify-0.7, curl, cloudflare-warp
Maintainer: $MAINTAINER
Description: Cloudflare WARP tray indicator for Linux
 A simple AppIndicator to control Cloudflare WARP (warp-cli) from system tray.
EOF

# Post-install script
cat > "$BUILD_DIR/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e
echo ">>> warp-indicator postinst: configuring Cloudflare WARP"

# Enable & start warp-svc if available
if systemctl list-unit-files --type=service | grep -q "^warp-svc"; then
    systemctl enable warp-svc || true
    systemctl start warp-svc || true
fi
warp-cli registration new || true
warp-cli status || true

# Refresh desktop database
update-desktop-database /usr/share/applications/ || true

echo ">>> WARP setup completed."
exit 0
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# Post-remove script
cat > "$BUILD_DIR/DEBIAN/postrm" <<'EOF'
#!/bin/bash
set -e
echo ">>> warp-indicator postrm: cleaning up"
rm -f /etc/xdg/autostart/warp-indicator.desktop
rm -f /usr/local/bin/warp-indicator
rm -rf /usr/share/doc/warp-indicator
rm -f /usr/share/applications/warp-indicator.desktop
rm -f /usr/share/icons/warp-indicator/logo.dark.svg
rm -f /usr/share/icons/warp-indicator/logo.light.svg
update-desktop-database /usr/share/applications/ || true
exit 0
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postrm"

# Copy LICENSE if exists
if [ -f LICENSE ]; then
    install -m 644 LICENSE "$BUILD_DIR/usr/share/doc/$PKGNAME/copyright"
else
    echo "Warning: LICENSE file not found."
fi

# Build .deb
OUTPUT_DEB="${PWD}/${PKGNAME}_${VERSION}.deb"
dpkg-deb --build "$BUILD_DIR" "$OUTPUT_DEB"
echo "✅ Built package: ${OUTPUT_DEB}"
