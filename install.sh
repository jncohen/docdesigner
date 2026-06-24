#!/usr/bin/env bash
# =============================================================================
# install.sh
#
# Copies docdesignertemplate.tex, default.csl, fonts/, and styles/ to a local
# managed directory.
#
# Usage:
#   bash install.sh                          # installs to ~/Templates/docdesigner/
#   docdesigner_template_DIR=/custom/path bash install.sh
#
# Two use cases:
#   (A) Set up a managed master copy that fetch-template.sh keeps current.
#       Point all projects at this location via YAML:
#         template: ~/Templates/docdesigner/docdesignertemplate.tex
#
#   (B) Freeze a local copy inside a project directory for archival:
#         docdesigner_template_DIR=./templates bash install.sh
#       This locks the project to the current version.
#
# Font files must be populated first:
#   bash scripts/get-fonts.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${docdesigner_template_DIR:-$HOME/Templates/docdesigner}"

echo "Installing docdesigner to: $DEST"
mkdir -p "$DEST/fonts"

# Copy template
cp "$SCRIPT_DIR/inst/templates/docdesignertemplate.tex" "$DEST/docdesignertemplate.tex"
echo "  Copied docdesignertemplate.tex"

# Copy fonts if present
if [ -d "$SCRIPT_DIR/inst/fonts" ] && [ "$(ls -A "$SCRIPT_DIR/inst/fonts"/*.otf "$SCRIPT_DIR/inst/fonts"/*.ttf 2>/dev/null)" ]; then
  cp "$SCRIPT_DIR/inst/fonts"/*.otf "$SCRIPT_DIR/inst/fonts"/*.ttf "$DEST/fonts/" 2>/dev/null || true
  echo "  Copied fonts/"
else
  echo "  WARNING: inst/fonts/ directory is empty. Run scripts/get-fonts.sh first."
  echo "           Without font files, fontset presets will fall back to defaults."
fi

# Copy CSL
if [ -f "$SCRIPT_DIR/inst/csl/default.csl" ]; then
  cp "$SCRIPT_DIR/inst/csl/default.csl" "$DEST/default.csl"
  echo "  Copied default.csl"
fi

if [ -d "$SCRIPT_DIR/inst/styles" ]; then
  cp -R "$SCRIPT_DIR/inst/styles" "$DEST/styles"
  echo "  Copied styles/"
fi

echo ""
echo "Installation complete."
echo ""
echo "Add to your document YAML:"
echo "  template: $DEST/docdesignertemplate.tex"
echo "  csl: $DEST/default.csl"
echo ""
echo "For fontset presets (humanities/demography/methods), also add:"
echo "  fontpath: $DEST/fonts/"
