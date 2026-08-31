#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash "$ROOT_DIR/script/verify_entitlements.sh" "$ROOT_DIR/MenuBarIO/MenuBarIO.entitlements"

if rg -n 'ENABLE_OUTGOING_NETWORK_CONNECTIONS = YES;|ENABLE_USER_SELECTED_FILES = (readonly|readwrite);' MenuBarIO.xcodeproj/project.pbxproj; then
  echo "Privacy audit failed: Xcode still enables network or user-selected file access." >&2
  exit 1
fi

forbidden_pattern='analytics|telemetry|sentry|firebase|mixpanel|amplitude|crashlytics|posthog|bugsnag|appcenter'
if rg -n -i --glob '*.swift' "$forbidden_pattern" MenuBarIO; then
  echo "Privacy audit failed: telemetry or analytics code was found." >&2
  exit 1
fi

if rg -n --glob '*.swift' '@AS\(Key\.newVersionNotification|hasUpdate\(' MenuBarIO; then
  echo "Privacy audit failed: an automatic update check was found." >&2
  exit 1
fi

if rg -n --glob '*.swift' '@AS\(Key\.(internetMonitoring|trafficButton|disableTrafficButtonLabel|fastMonitor)|startEthernetMonitoring|stopEthernetMonitoring|ethernetTraffic|trafficMonitorRunning|ETHERNET_DOT' MenuBarIO; then
  echo "Privacy audit failed: removed Ethernet traffic monitoring was found." >&2
  exit 1
fi

if rg -n --glob '*.swift' 'URLSession|URLRequest|NSURLSession|NSURLConnection|URLProtocol|NWConnection|NWListener|NWPathMonitor|CFSocket|CFNetwork|URL\(' MenuBarIO; then
  echo "Privacy audit failed: the minimal app must not contain network client code." >&2
  exit 1
fi

for update_feed_key in PortGlanceUpdateFeedURL MenuBarIOUpdateFeedURL; do
  if plutil -extract "$update_feed_key" raw Info.plist >/dev/null 2>&1; then
    echo "Privacy audit failed: the removed update feed is still configured." >&2
    exit 1
  fi
done

echo "Privacy audit passed: sandbox with USB and Bluetooth entitlements; no telemetry, network client code, or Ethernet traffic monitor."
