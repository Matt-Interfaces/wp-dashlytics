#!/bin/bash

# WP Dashlytics Plugin Build Script
# Creates an installable ZIP archive for WordPress.

set -e

echo "🚀 WP Dashlytics Plugin Build Script"
echo "===================================="

# Variables
PLUGIN_NAME="dashlytics"
VERSION="0.8.4"
BUILD_DIR="./build"
DIST_DIR="./dist"

# Output colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: cleanup
echo -e "${YELLOW}📦 Cleaning old builds...${NC}"
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
rm -f app/public/build/*.map.js
mkdir -p "$BUILD_DIR/$PLUGIN_NAME"
mkdir -p "$DIST_DIR"

# Step 2: install dependencies and build the Svelte apps
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
cd app
if [ "${CI}" = "true" ]; then
    npm ci --legacy-peer-deps
else
    npm install --legacy-peer-deps
fi
echo -e "${YELLOW}🔨 Building Svelte components...${NC}"
npm run build
cd ..

# Step 3: copy files
echo -e "${YELLOW}📁 Copying plugin files...${NC}"

# Core files
cp dashlytics-matomo.php "$BUILD_DIR/$PLUGIN_NAME/"
cp uninstall.php "$BUILD_DIR/$PLUGIN_NAME/"
cp readme.txt "$BUILD_DIR/$PLUGIN_NAME/"
cp README.md "$BUILD_DIR/$PLUGIN_NAME/"
cp LICENSE "$BUILD_DIR/$PLUGIN_NAME/"

# Assets
mkdir -p "$BUILD_DIR/$PLUGIN_NAME/assets/css"
mkdir -p "$BUILD_DIR/$PLUGIN_NAME/assets/js"
cp -r assets/css/* "$BUILD_DIR/$PLUGIN_NAME/assets/css/"
if [ -d "assets/js" ]; then
    cp -r assets/js/* "$BUILD_DIR/$PLUGIN_NAME/assets/js/"
fi
cp assets/*.gif "$BUILD_DIR/$PLUGIN_NAME/assets/" 2>/dev/null || true
cp assets/*.png "$BUILD_DIR/$PLUGIN_NAME/assets/" 2>/dev/null || true
if [ -d "assets/images" ]; then
    mkdir -p "$BUILD_DIR/$PLUGIN_NAME/assets/images"
    cp -r assets/images/* "$BUILD_DIR/$PLUGIN_NAME/assets/images/"
fi

# Compiled Svelte builds (only JS and CSS)
mkdir -p "$BUILD_DIR/$PLUGIN_NAME/app/public/build"
cp app/public/build/*.js "$BUILD_DIR/$PLUGIN_NAME/app/public/build/"
cp app/public/build/*.css "$BUILD_DIR/$PLUGIN_NAME/app/public/build/"

# Includes (PHP classes)
mkdir -p "$BUILD_DIR/$PLUGIN_NAME/includes"
if [ -d "includes" ]; then
    cp -r includes/*.php "$BUILD_DIR/$PLUGIN_NAME/includes/"
fi

# Plugin Update Checker (vendored library for GitHub-based updates)
if [ -d "includes/plugin-update-checker" ]; then
    cp -r includes/plugin-update-checker "$BUILD_DIR/$PLUGIN_NAME/includes/"
fi

# Languages (.pot template + compiled .mo and source .po)
mkdir -p "$BUILD_DIR/$PLUGIN_NAME/languages"
if ls languages/*.{pot,po,mo} >/dev/null 2>&1; then
    cp languages/*.{pot,po,mo} "$BUILD_DIR/$PLUGIN_NAME/languages/"
fi

# Step 4: create ZIP archive
echo -e "${YELLOW}📦 Creating ZIP archive...${NC}"
cd "$BUILD_DIR"
zip -r "../$DIST_DIR/${PLUGIN_NAME}-${VERSION}.zip" "$PLUGIN_NAME" -x "*.DS_Store" -x "*__MACOSX*"
cd ..

# Step 5: cleanup build staging dir
rm -rf "$BUILD_DIR"

# Done
echo ""
echo -e "${GREEN}✅ Build successful!${NC}"
echo -e "${GREEN}📦 Plugin ZIP: $DIST_DIR/${PLUGIN_NAME}-${VERSION}.zip${NC}"
echo ""
echo "Installation:"
echo "1. Go to WordPress Admin → Plugins → Add New → Upload Plugin"
echo "2. Select the ZIP file: ${PLUGIN_NAME}-${VERSION}.zip"
echo "3. Click 'Install Now' and then 'Activate'"

