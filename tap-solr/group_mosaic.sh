#!/bin/bash

# vips_mosaic.sh
# Uses VIPS to create a giant zoomable mosaic of labeled images grouped by TITLE
# Each image tile is square with label below, grouped by TITLE with a block header

#set -euo pipefail
set -vx

# === CONFIGURATION ===
INPUT_FILE="$1"
WORK_DIR="$2"
OUTPUT_IMAGE="$2_mosaic.jpg"
DZI_DIR="dzi_$2"
TILE_SIZE=1200
LABEL_HEIGHT=80
FONT_SIZE=26
GROUP_LABEL_HEIGHT=160
GROUP_LABEL_FONT_SIZE=64
BACKGROUND_COLOR="white"
PADDING=10
CANVAS_SIZE=$((TILE_SIZE - 2 * PADDING))

# === CLEANUP ===
rm -rf "$WORK_DIR" "$OUTPUT_IMAGE" "$DZI_DIR"
mkdir -p "$WORK_DIR"

# === GROUPING ===
echo "📁 Grouping images..."
while IFS=$'\t' read -r  TITLE SITE OP BURIAL filename KEY
do
  ((LINES++))
  #filename=$(basename "$img")
  outdir="$WORK_DIR/$TITLE"
  mkdir -p "$outdir"

  base="${filename%.thumb.jpg}"
  cp "labeled_images/${base}_labeled.jpg" "$outdir/"
  echo "→ Processing $filename into $outdir"
done < $INPUT_FILE

# === CREATE GROUP BLOCKS ===
echo "🧱 Assembling group blocks with VIPS..."
for group_dir in "$WORK_DIR"/*; do
  [ -d "$group_dir" ] || continue
  group=$(basename "$group_dir")
  group_out="$group_dir/__grid__.jpg"
  labeled_images=( "$group_dir"/*_labeled.jpg )

  if [[ ${#labeled_images[@]} -eq 0 ]]; then
    echo "⚠️  Skipping $group: no labeled images"
    continue
  fi

  # Compute layout
  count=${#labeled_images[@]}
  across=$(awk "BEGIN { print int(sqrt($count)) }")
  (( across < 1 )) && across=1

  echo "→ Building grid for group $group with $count images ($across across)..."

  # Build the grid
  vips arrayjoin "${labeled_images[*]}" "$group_dir/tmp_grid.jpg" \
    --across "$across" \
    --background "255 255 255"

  # Create a group label (gray background, tilewidth by labelheight)
  magick -density 150 -size ${TILE_SIZE}x${GROUP_LABEL_HEIGHT} \
    -background "rgb(220,220,220)" -fill black \
    -colorspace sRGB -type TrueColor \
    -gravity center -pointsize $GROUP_LABEL_FONT_SIZE \
    caption:"$group" "$group_dir/group_label.png"

  # Stretch group label to match grid width
  grid_width=$(vipsheader -f width "$group_dir/tmp_grid.jpg")
  scale=$(awk "BEGIN { print $grid_width / $TILE_SIZE }")
  vips resize "$group_dir/group_label.png" "$group_dir/tmp_label.png" "$scale"

  # Stack label + grid vertically
  vips join "$group_dir/tmp_label.png" "$group_dir/tmp_grid.jpg" "$group_out" vertical

  # Clean up temp files
  rm "$group_dir/group_label.png" "$group_dir/tmp_label.png" "$group_dir/tmp_grid.jpg"

  echo "✅ Done: $group_out"
done

# === FINAL MOSAIC ===
echo "🧩 Joining all group blocks into full mosaic..."

# --- Config ---
TILE_WIDTH=2000
TILE_HEIGHT=2200
SPACING=10
TILE_GEOMETRY="${TILE_WIDTH}x${TILE_HEIGHT}+${SPACING}+${SPACING}"
JPEG_QUALITY=95

# Compute layout, a double square
DIRS=( $WORK_DIR/* )
count=${#DIRS[@]}
across=$(awk "BEGIN { print int(sqrt($count * 2)) }")
(( across < 1 )) && across=1

# Create mosaic ---
echo "Creating high-res mosaic... $across x "
FILES=( $WORK_DIR/*/__grid__.jpg )
gm montage -tile ${across}x -geometry "$TILE_GEOMETRY" "${FILES[@]}" "$OUTPUT_IMAGE"

# --- Step 3: Generate Deep Zoom tiles ---
echo "Generating DZI tiles..."
vips dzsave "$OUTPUT_IMAGE" "$DZI_DIR" \
  --layout dz \
  --tile-size 254 \
  --overlap 1 \
  --suffix .jpg[Q=$JPEG_QUALITY]

echo "✅ Done! OpenSeadragon viewer can now load $DZI_DIR.dzi"

