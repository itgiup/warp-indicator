#!/usr/bin/env python3
import gi
import subprocess
import threading
import time

gi.require_version("Gtk", "3.0")
gi.require_version("AppIndicator3", "0.1")

from gi.repository import Gtk, AppIndicator3, Notify, GLib


APP_ID = "warp-indicator"
CHECK_INTERVAL = 5  # seconds


class WarpIndicator:
    def __init__(self):
        self.indicator = AppIndicator3.Indicator.new(
            APP_ID,
            "network-vpn",
            AppIndicator3.IndicatorCategory.APPLICATION_STATUS,
        )
        self.indicator.set_status(AppIndicator3.IndicatorStatus.ACTIVE)

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

        # Start background thread to monitor connection
        self.running = True
        threading.Thread(target=self.status_loop, daemon=True).start()

    def run_cmd(self, cmd):
        """Run shell command and return output."""
        try:
            return subprocess.check_output(cmd, shell=True, text=True).strip()
        except subprocess.CalledProcessError:
            return ""

    def get_status(self):
        """Check WARP connection status."""
        out = self.run_cmd("warp-cli status")
        if "Connected" in out:
            return "connected"
        elif "Disconnected" in out:
            return "disconnected"
        else:
            return "error"

    def connect_warp(self, _=None):
        self.run_cmd("warp-cli connect")
        Notify.Notification.new("WARP", "Connecting to WARP...", None).show()

    def disconnect_warp(self, _=None):
        self.run_cmd("warp-cli disconnect")
        Notify.Notification.new("WARP", "Disconnected from WARP", None).show()

    def status_loop(self):
        """Background loop to keep WARP connected."""
        while self.running:
            status = self.get_status()
            GLib.idle_add(self.update_indicator, status)

            # Auto-reconnect if lost
            if status != "connected":
                self.run_cmd("warp-cli connect")

            time.sleep(CHECK_INTERVAL)

    def update_indicator(self, status):
        if status == "connected":
            self.indicator.set_icon("network-vpn")
            self.connect_item.set_sensitive(False)
            self.disconnect_item.set_sensitive(True)
        elif status == "disconnected":
            self.indicator.set_icon("network-error")
            self.connect_item.set_sensitive(True)
            self.disconnect_item.set_sensitive(False)
        else:
            self.indicator.set_icon("dialog-warning")
            self.connect_item.set_sensitive(True)
            self.disconnect_item.set_sensitive(True)

    def quit(self, _):
        self.running = False
        Notify.uninit()
        Gtk.main_quit()


if __name__ == "__main__":
    WarpIndicator()
    Gtk.main()
