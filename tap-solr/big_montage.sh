#!/bin/bash

# set -e

# CONFIG
INPUT_DIR="input_images"
GROUP_DIR="grouped"
TILES_DIR="tiles"
BLOCKS_DIR="blocks"
FINAL_DIR="final"
FINAL_IMAGE="full_montage.tif"

TILE_WIDTH=300
TILE_HEIGHT=300
LABEL_HEIGHT=40
TILE_TOTAL_HEIGHT=$((TILE_HEIGHT + LABEL_HEIGHT))

SECTION_LABEL_HEIGHT=120
SECTION_FONT_SIZE=64

MAX_COLUMNS=40   # For per-group montage
GRID_ASPECT=1.5  # Final grid layout

# PREP
rm -rf "$GROUP_DIR"/* "$TILES_DIR"/* "$BLOCKS_DIR"/* "$FINAL_DIR/$FINAL_IMAGE"
mkdir -p "$GROUP_DIR" "$TILES_DIR" "$BLOCKS_DIR" "$FINAL_DIR"

echo "🔤 Grouping images by first prefix..."
shopt -s nullglob
for file in "$INPUT_DIR"/*.jpeg; do
  base=$(basename "$file")
  prefix=$(echo "$base" \
    | perl -pe 's/^(tap|nkh|nml|npw)[- ](\d+)/\1\2/;s/ro-\d+.thumb/ro-999.thumb/;s/.thumb.jpeg//;' \
    | perl -pe 's/^2023.*/2023/;s/^img.*/img/i;s/(sq\-\w).*/\1/;s/(\-op\-?\d+).*/\1/;s/(nnt|kwpv).*/\1/;' \
    | perl -pe 's/ro?l?l?\-?(\d+)/r\1/;s/op\-/op/;s/^(op\w+)\-.*/\1/;s/^t\-(\w+)/tno/;s/^scan.*/\scan/' \
    | cut -f1-2 -d '-')
  check=$(grep "$prefix" patterns.txt | head -1)
  if [ ! "$check" ]; then
    prefix='other'
  fi
  echo "$base -> $prefix ($check)"
  mkdir -p "$GROUP_DIR/$prefix"
  cp "$file" "$GROUP_DIR/$prefix/"
done

echo "🧱 Building tiles and group montages..."
for d in "$GROUP_DIR"/*; do
  prefix=$(basename "$d")
  tile_folder="$TILES_DIR/$prefix"
  mkdir -p "$tile_folder"

  echo "  🔡 Processing group: $prefix"

  for img in "$d"/*.jpeg; do
    base=$(basename "$img")
    label="${base%.*}"
    tile="$tile_folder/$base"
    echo "converting $img"
    gm convert "$img" \
      -resize "${TILE_WIDTH}x${TILE_HEIGHT}^" \
      -gravity center \
      -extent ${TILE_WIDTH}x${TILE_HEIGHT} \
      \( -size ${TILE_WIDTH}x${LABEL_HEIGHT} \
         -background white -fill black \
         -gravity center -pointsize 16 \
         label:"$label" \) \
      -append "$tile"
  done

  tile_images=("$tile_folder"/*.jpeg)
  count=${#tile_images[@]}
  cols=$(awk -v n="$count" -v max="$MAX_COLUMNS" 'BEGIN {
    cols = int(sqrt(n) * 1.2); if (cols < 1) cols = 1; if (cols > max) cols = max; print cols;
  }')
  rows=$(( (count + cols - 1) / cols ))

  # Group montage
  group_montage="$BLOCKS_DIR/group_${prefix}.jpeg"
  gm montage "${tile_images[@]}" \
    -tile "${cols}x${rows}" \
    -geometry +0+0 \
    -background white \
    "$group_montage"

  # Add big prefix label on top
  label_img="$BLOCKS_DIR/label_${prefix}.jpeg"
  w=$(identify -format "%w" "$group_montage")
  gm convert -size ${w}x${SECTION_LABEL_HEIGHT} \
    -background white -fill black -gravity center \
    -pointsize $SECTION_FONT_SIZE label:"$prefix" "$label_img"

  gm convert "$label_img" "$group_montage" -append "$FINAL_DIR/section_${prefix}.jpeg"
done

echo "📐 Normalizing section widths..."
# Pad all sections to max width
max_width=0
for img in "$FINAL_DIR"/section_*.jpeg; do
  w=$(identify -format "%w" "$img")
  if [ "$w" -gt "$max_width" ]; then
    max_width=$w
  fi
done

for img in "$FINAL_DIR"/section_*.jpeg; do
  w=$(identify -format "%w" "$img")
  h=$(identify -format "%h" "$img")
  if [ "$w" -lt "$max_width" ]; then
    echo "  ➕ Padding $(basename "$img") from $w → $max_width"
    gm convert "$img" -background white -gravity northwest -extent ${max_width}x${h} "$img"
  fi
done

echo "🧱 Building final grid layout..."
sections=("$FINAL_DIR"/section_*.jpeg)
total=${#sections[@]}
cols=$(awk -v n="$total" -v aspect="$GRID_ASPECT" '
  BEGIN { c = int(sqrt(n) * aspect + 0.5); if (c < 1) c = 1; print c; }')
rows=$(( (total + cols - 1) / cols ))

gm montage "${sections[@]}" \
  -tile "${cols}x${rows}" \
  -geometry +0+0 \
  -background white \
  "$FINAL_DIR/$FINAL_IMAGE"

echo "✅ Final image created: $FINAL_DIR/$FINAL_IMAGE"
