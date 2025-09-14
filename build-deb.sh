#!/bin/bash
set -euo pipefail

PKGNAME="warp-indicator"
VERSION="1.0"
ARCH="all"
MAINTAINER="ITGiup <itgiup.com@gmail.com>"
BUILD_DIR="${PKGNAME}_${VERSION}"

# Cleanup
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/doc/$PKGNAME"

# Copy app (expects warp-indicator.py present in cwd)
install -m 755 warp-indicator.py "$BUILD_DIR/usr/bin/warp-indicator"

# Create desktop entry
cat > "$BUILD_DIR/usr/share/applications/$PKGNAME.desktop" <<'EOF'
[Desktop Entry]
Name=Warp Indicator
Comment=Show status and control Cloudflare WARP
Exec=/usr/bin/warp-indicator
Icon=network-vpn
Terminal=false
Type=Application
Categories=Network;
X-GNOME-Autostart-enabled=true
EOF

# Debian control file
cat > "$BUILD_DIR/DEBIAN/control" <<EOF
Package: $PKGNAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Depends: python3, python3-gi, gir1.2-appindicator3-0.1, gir1.2-notify-0.7
Maintainer: $MAINTAINER
Description: Tray indicator for Cloudflare WARP on Ubuntu (GNOME).
 A small AppIndicator to control Cloudflare WARP (warp-cli).
EOF

# Post-install script: check warp-cli availability
cat > "$BUILD_DIR/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e

echo ">>> warp-indicator postinst: checking for warp-cli"

if ! command -v warp-cli >/dev/null 2>&1; then
  echo "⚠️  warp-cli not found!"
  echo "Please install Cloudflare WARP client manually:"
  echo "  https://developers.cloudflare.com/warp-client/get-started/linux/"
else
  echo "✅ warp-cli detected"
fi

exit 0
EOF

chmod 0755 "$BUILD_DIR/DEBIAN/postinst"

# Post-remove script: cleanup installed files
cat > "$BUILD_DIR/DEBIAN/postrm" <<'EOF'
#!/bin/bash
set -e
echo ">>> warp-indicator postrm: cleaning up application files"
rm -f /usr/share/applications/warp-indicator.desktop
rm -f /usr/bin/warp-indicator
rm -rf /usr/share/doc/warp-indicator
exit 0
EOF

chmod 0755 "$BUILD_DIR/DEBIAN/postrm"

# Copy license if present (recommended)
if [ -f LICENSE ]; then
  install -m 644 LICENSE "$BUILD_DIR/usr/share/doc/$PKGNAME/copyright"
else
  echo "Warning: LICENSE file not found in current directory. Consider adding LICENSE (MIT)."
fi

# Build .deb
dpkg-deb --build "$BUILD_DIR"
echo "✅ Built package: ${BUILD_DIR}.deb"
