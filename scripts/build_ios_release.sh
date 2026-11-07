#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Read the release version from the checked-out source, not cached settings.
release_version="$(sed -n 's/^version: *//p' pubspec.yaml | tr -d '\r')"
build_name="${release_version%+*}"
build_number="${release_version##*+}"
if [[ ! "$build_number" =~ ^[0-9]+$ ]] || (( build_number < 7 )); then
  echo "Expected pubspec.yaml build number 7 or higher; found $release_version" >&2
  exit 1
fi

flutter clean
flutter pub get
flutter build ipa --release --build-name="$build_name" --build-number="$build_number" "$@"

# Fail before publishing if the packaged app differs from this release.
python3 - "$build_name" "$build_number" <<'PY'
import glob
import plistlib
import sys
import zipfile

ipas = glob.glob('build/ios/ipa/*.ipa')
if len(ipas) != 1:
    raise SystemExit(f'Expected one fresh IPA, found {len(ipas)}')
with zipfile.ZipFile(ipas[0]) as archive:
    paths = [p for p in archive.namelist()
             if p.startswith('Payload/') and p.endswith('.app/Info.plist')
             and p.count('/') == 2]
    if len(paths) != 1:
        raise SystemExit('Could not identify the main app Info.plist')
    info = plistlib.loads(archive.read(paths[0]))
if str(info.get('CFBundleShortVersionString')) != sys.argv[1]:
    raise SystemExit('IPA marketing version does not match pubspec.yaml')
if str(info.get('CFBundleVersion')) != sys.argv[2]:
    raise SystemExit('IPA build number does not match pubspec.yaml')
if info.get('ITSAppUsesNonExemptEncryption') is not False:
    raise SystemExit('IPA is missing the exempt encryption declaration')
print(f'Verified {ipas[0]}: version {sys.argv[1]}, build {sys.argv[2]}, exempt encryption')
PY
