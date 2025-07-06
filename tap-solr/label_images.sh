#!/bin/bash

# vips_mosaic.sh
# Uses VIPS to create a giant zoomable mosaic of labeled images grouped by prefix
# Each image tile is square with label below, grouped by prefix with a block header

#set -euo pipefail
set -vx

# === CONFIGURATION ===
INPUT_DIR="$1"
WORK_DIR="labeled_images"
OUTPUT_IMAGE="full_mosaic.jpg"
DZI_DIR="dzi_output"
TILE_SIZE=1000
LABEL_HEIGHT=60
FONT_SIZE=24
GROUP_LABEL_HEIGHT=160
GROUP_LABEL_FONT_SIZE=64
BACKGROUND_COLOR="white"
PADDING=10
CANVAS_SIZE=$((TILE_SIZE - 2 * PADDING))

echo "📁 Grouping and labeling images..."
find "$INPUT_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) | sort | while read -r img; do
  filename=$(basename "$img")

  base="${filename%.thumb.jpg}"
  labeled_img="$WORK_DIR/${base}_labeled.jpg"
  tmp_resized="$WORK_DIR/tmp_resized.jpg"
  tmp_combined="$WORK_DIR/tmp_combined.jpg"
  label_img="$WORK_DIR/tmp_label.png"

  echo "→ Processing $filename into $labeled_img"

  # Step 1: Resize image to fit inside TILE_SIZE while preserving aspect ratio
  magick "$img" \
    -resize ${CANVAS_SIZE}x${CANVAS_SIZE} \
    -gravity center \
    -background white \
    -extent ${TILE_SIZE}x${TILE_SIZE} \
    -colorspace sRGB -type TrueColor \
    "$tmp_resized"

  # Step 2: Label below image (same size width)
  magick -density 150 -size ${TILE_SIZE}x${LABEL_HEIGHT} \
    -background white -fill black \
    -gravity center -pointsize $FONT_SIZE \
    -colorspace sRGB -type TrueColor \
    caption:"${filename%.thumb.jpg}" "$label_img"

  # Step 3: Stack image + label vertically with vips arrayjoin
  magick \
    -colorspace sRGB -type TrueColor \
    "$tmp_resized" "$label_img" -append "$labeled_img"

  # Step 4: add a gray border
  magick "$labeled_img" \
    -bordercolor "#cccccc" -border 2x2 \
    -colorspace sRGB -type TrueColor \
    "$labeled_img"

  # Check image attributes
  vipsheader "$tmp_resized" "$labeled_img" "$label_img"

  # Clean up temp files
  rm "$tmp_combined" "$tmp_resized" "$label_img"

done

echo "✅ Done!"

