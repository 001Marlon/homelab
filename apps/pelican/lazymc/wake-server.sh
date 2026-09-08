#!/bin/sh
# Invoked by lazymc as the "server process". Doesn't run Minecraft itself -
# triggers start/stop on the actual server through the Pelican client API,
# then blocks until lazymc sends SIGTERM (it decided to sleep the server).

set -u

power() {
  curl -s -o /dev/null -X POST \
    -H "Authorization: Bearer ${PELICAN_API_KEY}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{\"signal\":\"$1\"}" \
    "${PELICAN_URL}/api/client/servers/${PELICAN_SERVER_UUID}/power"
}

stop_server() {
  power stop
  exit 0
}
trap stop_server TERM INT

power start

while true; do
  sleep 3600 &
  wait $!
done
