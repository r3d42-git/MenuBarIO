#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

forbidden_pattern='analytics|telemetry|sentry|firebase|mixpanel|amplitude|crashlytics|posthog|bugsnag|appcenter'
if rg -n -i --glob '*.swift' "$forbidden_pattern" MenuBarUSB; then
  echo "Privacy audit failed: telemetry or analytics code was found." >&2
  exit 1
fi

if rg -n --glob '*.swift' '@AS\(Key\.newVersionNotification|hasUpdate\(' MenuBarUSB; then
  echo "Privacy audit failed: an automatic update check was found." >&2
  exit 1
fi

if rg -n --glob '*.swift' '@AS\(Key\.(internetMonitoring|trafficButton|disableTrafficButtonLabel|fastMonitor)|startEthernetMonitoring|stopEthernetMonitoring|ethernetTraffic|trafficMonitorRunning|ETHERNET_DOT' MenuBarUSB; then
  echo "Privacy audit failed: removed Ethernet traffic monitoring was found." >&2
  exit 1
fi

if rg -n --glob '*.swift' 'URLSession|URLRequest|URL\(' MenuBarUSB; then
  echo "Privacy audit failed: the minimal app must not contain network client code." >&2
  exit 1
fi

if plutil -extract MenuBarUSBUpdateFeedURL raw Info.plist >/dev/null 2>&1; then
  echo "Privacy audit failed: the removed update feed is still configured." >&2
  exit 1
fi

echo "Privacy audit passed: no telemetry, network client code, or Ethernet traffic monitor."
