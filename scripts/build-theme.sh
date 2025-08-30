#!/bin/bash

# Iron Bulwark - Build Theme Script
# Creates a zip file of the theme for uploading to Ghost

set -e

THEME_DIR="/home/user/iron-bulwark/themes/iron-bulwark"
OUTPUT_ZIP="/home/user/iron-bulwark/iron-bulwark.zip"

echo "Building Iron Bulwark theme..."
echo "Theme directory: $THEME_DIR"
echo "Output: $OUTPUT_ZIP"

# Navigate to theme directory and create zip
cd "$THEME_DIR"
zip -r "$OUTPUT_ZIP" .

echo ""
echo "✅ Theme zip created successfully!"
echo "Location: $OUTPUT_ZIP"
echo ""
echo "Next steps:"
echo "1. Go to Ghost admin: https://iron-bulwark.org/ghost"
echo "2. Settings → Design → Upload theme"
echo "3. Upload the zip file"
echo "4. Activate the theme"
echo ""
echo "To rebuild after making changes:"
echo "cd /home/user/iron-bulwark/themes/iron-bulwark && zip -r ../iron-bulwark.zip ."
