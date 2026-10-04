#!/usr/bin/env bash
# =============================================================================
# scripts/get-fonts.sh
#
# Downloads OTF/TTF font files for docdesigner-template font presets into fonts/.
# All fonts are SIL Open Font License 1.1.
#
# Usage:
#   bash scripts/get-fonts.sh            # download to fonts/ (default)
#   FONTS_DIR=/path/to/fonts bash scripts/get-fonts.sh
#
# After running, commit the files:
#   git add inst/fonts/
#   git commit -m "chore: add bundled font files"
#
# Sources:
#   EB Garamond   — Georg Duffner & Octavio Pardo (Google Fonts / OFL 1.1)
#   XITS          — Ali Rasti Kerdar, aliftype/xits (OFL 1.1)
#   Source Serif  — Adobe, adobe-fonts/source-serif (OFL 1.1)
#   Fira Code     — Nikita Prokopov, tonsky/FiraCode (OFL 1.1)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
FONTS_DIR="${FONTS_DIR:-$REPO_DIR/inst/fonts}"

mkdir -p "$FONTS_DIR"

# Helper: download one file with a progress indicator
download() {
  local url="$1"
  local dest="$2"
  echo "  Fetching $(basename "$dest") ..."
  curl -fsSL --retry 3 "$url" -o "$dest"
}

# =============================================================================
# EB Garamond — fontset: humanities
# Source: octaviopardo/EBGaramond12 (OFL 1.1)
# Canonical: https://github.com/octaviopardo/EBGaramond12
# =============================================================================
echo "Downloading EB Garamond (humanities preset)..."
EBG_BASE="https://raw.githubusercontent.com/octaviopardo/EBGaramond12/master/fonts/otf"
download "$EBG_BASE/EBGaramond-Regular.otf"    "$FONTS_DIR/EBGaramond-Regular.otf"
download "$EBG_BASE/EBGaramond-Bold.otf"        "$FONTS_DIR/EBGaramond-Bold.otf"
download "$EBG_BASE/EBGaramond-Italic.otf"      "$FONTS_DIR/EBGaramond-Italic.otf"
download "$EBG_BASE/EBGaramond-BoldItalic.otf"  "$FONTS_DIR/EBGaramond-BoldItalic.otf"

# Garamond Math - math companion for humanities.
echo "Downloading Garamond Math (humanities preset, math)..."
GM_BASE="https://raw.githubusercontent.com/YuanshengZhao/Garamond-Math/master/fonts/otf"
download "$GM_BASE/Garamond-Math.otf" "$FONTS_DIR/Garamond-Math.otf"

# =============================================================================
# XITS — fontset: demography
# Source: aliftype/xits (OFL 1.1)
# Canonical: https://github.com/aliftype/xits
# =============================================================================
echo "Downloading XITS (demography preset)..."
XITS_BASE="https://raw.githubusercontent.com/aliftype/xits/master"
download "$XITS_BASE/XITS-Regular.otf"      "$FONTS_DIR/XITS-Regular.otf"
download "$XITS_BASE/XITS-Bold.otf"          "$FONTS_DIR/XITS-Bold.otf"
download "$XITS_BASE/XITS-Italic.otf"        "$FONTS_DIR/XITS-Italic.otf"
download "$XITS_BASE/XITS-BoldItalic.otf"    "$FONTS_DIR/XITS-BoldItalic.otf"
download "$XITS_BASE/XITSMath-Regular.otf"   "$FONTS_DIR/XITSMath-Regular.otf"
download "$XITS_BASE/XITSMath-Bold.otf"      "$FONTS_DIR/XITSMath-Bold.otf"

# =============================================================================
# Source Serif 4 — fontset: methods (body text)
# Source: adobe-fonts/source-serif, release branch (OFL 1.1)
# Canonical: https://github.com/adobe-fonts/source-serif
# =============================================================================
echo "Downloading Source Serif 4 (methods preset, body)..."
SS_BASE="https://github.com/adobe-fonts/source-serif/raw/release/OTF"
download "$SS_BASE/SourceSerif4-Regular.otf"    "$FONTS_DIR/SourceSerif4-Regular.otf"
download "$SS_BASE/SourceSerif4-Bold.otf"        "$FONTS_DIR/SourceSerif4-Bold.otf"
download "$SS_BASE/SourceSerif4-It.otf"          "$FONTS_DIR/SourceSerif4-It.otf"
download "$SS_BASE/SourceSerif4-BoldIt.otf"      "$FONTS_DIR/SourceSerif4-BoldIt.otf"

# =============================================================================
# Fira Code — fontset: methods (monospace / code blocks)
# Source: tonsky/FiraCode release zip v6.2 (OFL 1.1)
# Canonical: https://github.com/tonsky/FiraCode
# TTF files are distributed in the release zip, not in the source tree.
# =============================================================================
echo "Downloading Fira Code (methods preset, monospace)..."
FC_ZIP_URL="https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip"
FC_TMP=$(mktemp -d)
echo "  Fetching Fira_Code_v6.2.zip ..."
curl -fsSL --retry 3 "$FC_ZIP_URL" -o "$FC_TMP/firacode.zip"
unzip -j -q "$FC_TMP/firacode.zip" "ttf/FiraCode-Regular.ttf" "ttf/FiraCode-Bold.ttf" -d "$FONTS_DIR"
rm -rf "$FC_TMP"
echo "  Extracted FiraCode-Regular.ttf and FiraCode-Bold.ttf"

echo ""
echo "Done. Font files written to: $FONTS_DIR"
echo ""
echo "To commit:"
echo "  git add inst/fonts/"
echo "  git commit -m 'chore: add bundled font files'"
