#!/bin/bash
#
# build-dmg.sh — Baut Nook (Release) und packt es in eine verteilbare .dmg.
#
# Die App wird NICHT mit Developer ID signiert/notarisiert (kein Apple-Account
# nötig). Sie läuft ad-hoc-signiert; Nutzer müssen beim ersten Start einmalig
# „Trotzdem öffnen" in den Sicherheitseinstellungen bestätigen. Siehe README.
#
# Nutzung:  ./scripts/build-dmg.sh
# Ergebnis: Nook-<version>.dmg im Projekt-Wurzelverzeichnis.
#
set -euo pipefail

SCHEME="Nook"
APP_NAME="Nook"
PROJECT="Nook.xcodeproj"

# Immer vom Projekt-Wurzelverzeichnis aus arbeiten (Skript liegt in scripts/).
cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "▸ Baue $SCHEME (Release) …"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$WORK/dd" \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  build >/dev/null

APP="$WORK/dd/Build/Products/Release/$APP_NAME.app"
[ -d "$APP" ] || { echo "✗ Build-Produkt nicht gefunden: $APP"; exit 1; }

VERSION="$(defaults read "$APP/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")"
OUT="$APP_NAME-$VERSION.dmg"

echo "▸ Packe DMG (Version $VERSION) …"
STAGE="$WORK/stage"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"   # Drag-to-install-Ziel

rm -f "$OUT"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE" \
  -ov -format UDZO \
  "$OUT" >/dev/null

echo "✓ Fertig: $OUT"
echo "  SHA-256: $(shasum -a 256 "$OUT" | awk '{print $1}')"
