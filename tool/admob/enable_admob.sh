#!/usr/bin/env bash
# Turns on AdMob banner ads (they are OFF in v1). See ADS.md first.
#
# Usage:
#   tool/admob/enable_admob.sh <ADMOB_APP_ID> <BANNER_AD_UNIT_ID>
#
# Google's TEST ids (safe for development, never use real ids while testing):
#   tool/admob/enable_admob.sh ca-app-pub-3940256099942544~3347511713 ca-app-pub-3940256099942544/6300978111
#
# What it does:
#   1. adds the google_mobile_ads package (Apache-2.0),
#   2. installs the AdMob backend (with Google UMP consent) in lib/ads/,
#   3. sets AppConfig.ads.enabled = true,
#   4. adds the AdMob app id to AndroidManifest.xml and allows INTERNET
#      (release builds have no internet permission while ads are off).
# Afterwards you MUST update the privacy policy, the Play "Contains ads"
# declaration and the Data safety form (see ADS.md).
set -euo pipefail

if [ $# -ne 2 ]; then
  sed -n '2,12p' "$0"
  exit 1
fi
APP_ID="$1"
BANNER_ID="$2"
case "$APP_ID" in ca-app-pub-*~*) ;; *) echo "App id must look like ca-app-pub-XXXX~YYYY" >&2; exit 1;; esac
case "$BANNER_ID" in ca-app-pub-*/*) ;; *) echo "Banner id must look like ca-app-pub-XXXX/YYYY" >&2; exit 1;; esac

cd "$(dirname "$0")/../.."
MANIFEST=android/app/src/main/AndroidManifest.xml

if grep -q 'com.google.android.gms.ads.APPLICATION_ID' "$MANIFEST"; then
  echo "AdMob already enabled." >&2
  exit 1
fi

flutter pub add google_mobile_ads
sed "s|BANNER_UNIT_ID_PLACEHOLDER|${BANNER_ID}|" tool/admob/ad_backend_admob.dart.tmpl > lib/ads/ad_backend.dart
sed -i.bak 's/AdsConfig(enabled: false)/AdsConfig(enabled: true)/' lib/config/app_config.dart && rm lib/config/app_config.dart.bak
sed -i.bak "s|<!-- ADMOB_APP_ID_PLACEHOLDER -->|<meta-data android:name=\"com.google.android.gms.ads.APPLICATION_ID\" android:value=\"${APP_ID}\" />|" "$MANIFEST"
sed -i.bak '/SATR_NO_INTERNET/d' "$MANIFEST" && rm "$MANIFEST.bak"

flutter analyze
echo
echo "AdMob enabled. Next steps (ADS.md): update PRIVACY.md and the in-app privacy text,"
echo "declare ads + Data safety in Play Console, test with TEST ids before real ones."
