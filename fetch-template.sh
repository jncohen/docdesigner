#!/usr/bin/env bash
# =============================================================================
# fetch-template.sh
#
# Pulls the latest docdesignertemplate.tex, default.csl, and font files from the
# docdesigner-template GitHub repository (main branch) into a local managed
# directory.  Run whenever you want to update to the current version.
#
# Usage:
#   bash fetch-template.sh                        # update ~/Templates/docdesigner/
#   docdesigner_template_DIR=/custom/path bash fetch-template.sh
#   docdesigner_BRANCH=v1.0.0 bash fetch-template.sh      # pin to a specific tag
#
# After updating, any project that sets
#   template: ~/Templates/docdesigner/docdesignertemplate.tex
# will use the new version on next compile.  Projects with frozen local copies
# (installed via install.sh with a project-local DEST) are unaffected.
# =============================================================================

set -euo pipefail

REPO="https://raw.githubusercontent.com/jncohen/docdesigner-template"
BRANCH="${docdesigner_BRANCH:-main}"
BASE="$REPO/$BRANCH"
DEST="${docdesigner_template_DIR:-$HOME/Templates/docdesigner}"

echo "Fetching docdesigner-template ($BRANCH) to: $DEST"
mkdir -p "$DEST/fonts"

fetch() {
  local url="$1"
  local dest="$2"
  echo "  ${url##*/} -> $dest"
  curl -fsSL --retry 3 "$url" -o "$dest"
}

# --- Core files ---
fetch "$BASE/inst/templates/docdesignertemplate.tex"  "$DEST/docdesignertemplate.tex"
fetch "$BASE/inst/csl/default.csl"            "$DEST/default.csl"

# --- Font files (all presets) ---
echo "Fetching fonts..."

# EB Garamond (humanities)
for f in EBGaramond-Regular.otf EBGaramond-Bold.otf \
          EBGaramond-Italic.otf EBGaramond-BoldItalic.otf; do
  fetch "$BASE/inst/fonts/$f" "$DEST/fonts/$f"
done

# XITS (demography)
for f in XITS-Regular.otf XITS-Bold.otf XITS-Italic.otf XITS-BoldItalic.otf; do
  fetch "$BASE/inst/fonts/$f" "$DEST/fonts/$f"
done

# Source Serif 4 (methods body)
for f in SourceSerif4-Regular.otf SourceSerif4-Bold.otf \
          SourceSerif4-It.otf SourceSerif4-BoldIt.otf; do
  fetch "$BASE/inst/fonts/$f" "$DEST/fonts/$f"
done

# Fira Code (methods mono)
for f in FiraCode-Regular.ttf FiraCode-Bold.ttf; do
  fetch "$BASE/inst/fonts/$f" "$DEST/fonts/$f"
done

echo ""
echo "Update complete.  Template and fonts are at: $DEST"
echo ""
echo "Add to your document YAML:"
echo "  template: $DEST/docdesignertemplate.tex"
echo "  csl: $DEST/default.csl"
echo ""
echo "For fontset presets (humanities/demography/methods), also add:"
echo "  fontpath: $DEST/fonts/"
