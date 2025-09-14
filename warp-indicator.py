#!/usr/bin/env python3
import gi
import subprocess
import threading
import time
import os

gi.require_version("Gtk", "3.0")
gi.require_version("AppIndicator3", "0.1")

from gi.repository import Gtk, AppIndicator3, Notify, GLib

APP_ID = "warp-indicator"
CHECK_INTERVAL = 5  # seconds

# Icons (tương ứng với package mới)
CONNECTED_ICON = "/usr/share/icons/warp-indicator/logo.light.svg"
DISCONNECTED_ICON = "/usr/share/icons/warp-indicator/logo.dark.svg"
ERROR_ICON = "dialog-warning"

class WarpIndicator:
    def __init__(self):
        self.indicator = AppIndicator3.Indicator.new(
            APP_ID, DISCONNECTED_ICON, AppIndicator3.IndicatorCategory.APPLICATION_STATUS
        )
        self.indicator.set_status(AppIndicator3.IndicatorStatus.ACTIVE)

        # Menu
        self.menu = Gtk.Menu()
        self.connect_item = Gtk.MenuItem(label="Connect WARP")
        self.connect_item.connect("activate", self.connect_warp)
        self.menu.append(self.connect_item)

        self.disconnect_item = Gtk.MenuItem(label="Disconnect WARP")
        self.disconnect_item.connect("activate", self.disconnect_warp)
        self.menu.append(self.disconnect_item)

        self.menu.append(Gtk.SeparatorMenuItem())
        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", self.quit)
        self.menu.append(quit_item)

        self.menu.show_all()
        self.indicator.set_menu(self.menu)

        Notify.init(APP_ID)

        # State
        self.running = True
        self.user_disconnected = False

        # Start monitoring thread
        threading.Thread(target=self.status_loop, daemon=True).start()

    def run_cmd(self, cmd):
        """Run shell command safely."""
        try:
            return subprocess.check_output(cmd, shell=True, text=True).strip()
        except subprocess.CalledProcessError:
            return ""

    def get_status(self):
        """Check WARP status."""
        out = self.run_cmd("warp-cli status")
        if "Connected" in out:
            return "connected"
        elif "Disconnected" in out:
            return "disconnected"
        elif "Registration Missing" in out:
            return "registration_missing"
        else:
            return "error"

    def accept_terms(self):
        """Popup to accept Terms of Service."""
        dialog = Gtk.MessageDialog(
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK_CANCEL,
            text="Cloudflare WARP Terms of Service",
        )
        dialog.format_secondary_text(
            "You must accept the Terms of Service to use WARP.\nPress OK to Accept."
        )
        response = dialog.run()
        dialog.destroy()
        if response == Gtk.ResponseType.OK:
            Notify.Notification.new("WARP", "Launching registration...", None).show()
            self.setup_warp()

    def setup_warp(self):
        """Register + set mode + connect, support new & old warp-cli."""
        help_text = self.run_cmd("warp-cli help")
        if "registration" in help_text:
            # New warp-cli syntax
            self.run_cmd("warp-cli registration new || true")
            self.run_cmd("warp-cli mode warp || true")
        else:
            # Old syntax
            self.run_cmd("warp-cli register || true")
            self.run_cmd("warp-cli set-mode warp || true")
        self.run_cmd("warp-cli connect || true")

    def connect_warp(self, _=None):
        self.user_disconnected = False
        self.run_cmd("warp-cli connect || true")
        Notify.Notification.new("WARP", "Connecting to WARP...", None).show()

    def disconnect_warp(self, _=None):
        self.user_disconnected = True
        self.run_cmd("warp-cli disconnect || true")
        Notify.Notification.new("WARP", "Disconnected from WARP", None).show()

    def status_loop(self):
        """Background monitor."""
        while self.running:
            status = self.get_status()
            GLib.idle_add(self.update_indicator, status)

            # Accept Terms popup
            if status == "registration_missing":
                GLib.idle_add(self.accept_terms)

            # Auto reconnect if disconnected and user didn't manually disconnect
            elif status != "connected" and not self.user_disconnected:
                self.run_cmd("warp-cli connect || true")

            time.sleep(CHECK_INTERVAL)

    def update_indicator(self, status):
        if status == "connected":
            if os.path.exists(CONNECTED_ICON):
                self.indicator.set_icon(CONNECTED_ICON)
            else:
                self.indicator.set_icon("network-vpn")
            self.connect_item.set_sensitive(False)
            self.disconnect_item.set_sensitive(True)
        elif status == "disconnected":
            if os.path.exists(DISCONNECTED_ICON):
                self.indicator.set_icon(DISCONNECTED_ICON)
            else:
                self.indicator.set_icon("network-vpn")
            self.connect_item.set_sensitive(True)
            self.disconnect_item.set_sensitive(False)
        else:
            self.indicator.set_icon(ERROR_ICON)
            self.connect_item.set_sensitive(True)
            self.disconnect_item.set_sensitive(True)

    def quit(self, _):
        self.running = False
        Notify.uninit()
        Gtk.main_quit()


if __name__ == "__main__":
    WarpIndicator()
    Gtk.main()
