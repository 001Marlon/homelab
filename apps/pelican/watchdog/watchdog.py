"""
Backstop for lazymc. Independently watches the real Minecraft server via a
status ping (not through lazymc) and force-stops it through the Pelican
client API if it's been idle too long. lazymc has repeatedly gotten stuck
internally and stopped signaling the server to sleep (see incident notes in
wake-server.sh/lazymc.toml) - this exists so a stuck lazymc doesn't leave
the server running indefinitely, wasting resources.
"""

import json
import os
import socket
import time
import urllib.request

from mcstatus import JavaServer

MC_HOST = os.environ.get("MC_HOST", "host.docker.internal")
MC_PORT = int(os.environ.get("MC_PORT", "25567"))
PANEL_URL = os.environ["PELICAN_URL"]
API_KEY = os.environ["PELICAN_API_KEY"]
SERVER_UUID = os.environ["PELICAN_SERVER_UUID"]
# Longer than lazymc's own sleep_after - this only acts if lazymc failed to.
IDLE_TIMEOUT = int(os.environ.get("IDLE_TIMEOUT", "900"))
CHECK_INTERVAL = int(os.environ.get("CHECK_INTERVAL", "60"))


def is_server_running():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(3)
    try:
        s.connect((MC_HOST, MC_PORT))
        return True
    except OSError:
        return False
    finally:
        s.close()


def get_player_count():
    try:
        server = JavaServer.lookup(f"{MC_HOST}:{MC_PORT}")
        return server.status().players.online
    except Exception as e:
        print(f"watchdog: status ping failed: {e}", flush=True)
        return None


def stop_server():
    req = urllib.request.Request(
        f"{PANEL_URL}/api/client/servers/{SERVER_UUID}/power",
        data=json.dumps({"signal": "stop"}).encode(),
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    urllib.request.urlopen(req, timeout=10)


def main():
    last_seen_player_at = None
    while True:
        time.sleep(CHECK_INTERVAL)

        if not is_server_running():
            last_seen_player_at = None
            continue

        count = get_player_count()
        if count is None:
            # transient probe failure (e.g. still booting) - don't act on it
            continue

        if count > 0:
            last_seen_player_at = time.time()
            continue

        if last_seen_player_at is None:
            last_seen_player_at = time.time()
            continue

        idle_for = time.time() - last_seen_player_at
        if idle_for >= IDLE_TIMEOUT:
            print(f"watchdog: idle for {idle_for:.0f}s (>= {IDLE_TIMEOUT}s) and lazymc hasn't stopped it, forcing stop", flush=True)
            try:
                stop_server()
            except Exception as e:
                print(f"watchdog: stop request failed: {e}", flush=True)
            last_seen_player_at = None


if __name__ == "__main__":
    main()
