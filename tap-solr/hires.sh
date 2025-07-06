#!/bin/bash
set -euo pipefail

# --- Config ---
TILE_WIDTH=1000
TILE_HEIGHT=1200
SPACING=10
TILE_GEOMETRY="${TILE_WIDTH}x${TILE_HEIGHT}+${SPACING}+${SPACING}"
TILE_GLOB="tiles/*/__grid__.jpg"
OUTPUT_IMAGE="full_mosaic.jpg"
DZI_DIR="dzi_output"
JPEG_QUALITY=95


# --- Step 2: Create mosaic ---
echo "Creating high-res mosaic..."
gm montage -tile 30x -geometry "$TILE_GEOMETRY" tiles/*/__grid__.jpg "$OUTPUT_IMAGE"

# --- Step 3: Generate Deep Zoom tiles ---
echo "Generating DZI tiles..."
vips dzsave "$OUTPUT_IMAGE" "$DZI_DIR" \
  --layout dz \
  --tile-size 254 \
  --overlap 1 \
  --suffix .jpg[Q=$JPEG_QUALITY]

echo "✅ Done! Output:"
