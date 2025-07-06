#!/bin/bash

# montage_full.sh
# Create a single labeled mosaic of all images grouped by prefix
# Each image tile is 600x600px, labeled with filename
# Each group is labeled at the top with its prefix

set -euo pipefail

# === CONFIGURATION ===
INPUT_DIR="$1"
WORK_DIR="tiles"
FINAL_IMAGE="full_mosaic.jpg"
OUTPUT_DZI_DIR="dzi_output"
TILE_SIZE=600
LABEL_HEIGHT=40
GROUP_LABEL_HEIGHT=60
SPACING=20
FONT_SIZE=20

# === CLEANUP ===
rm -rf "$WORK_DIR" "$FINAL_IMAGE" "$OUTPUT_DZI_DIR"
mkdir -p "$WORK_DIR"

# === GROUPING ===
echo "🔍 Grouping images by prefix..."
find "$INPUT_DIR" -type f -iname '*.jpg' -o -iname '*.jpeg' | while read -r img; do
  filename=$(basename "$img")
  prefix=$(echo "$filename" \
    | perl -pe 's/^(tk|tap|nkh|nml|npw)[- ](\d+)/\1\2/;s/ro-\d+.thumb/ro-999.thumb/;s/.thumb.jpeg//;' \
    | perl -pe 's/^86.*/86x/;s/^(2023\d+).*/\1/;s/^img.*/img/i;s/sq\-(\w).*/sq\1/;s/\-([a-z])\-/-sq\1-/;s/(\-op)\-?(\d+).*/\1\2/;s/(nnt|kwpv).*/\1/;' \
    | perl -pe 's/ro-(\d)(\d\d).*/r\1/;s/ro?l?l?\-?(\d+)/r\1/;s/op\-/op/;s/^(op\w+)\-.*/\1/;s/t-phu-lon.*/phu-lon/;s/^t\-(\w+)/tno/;s/^scan.*/\scan/;' \
    | perl -pe 's/tap.86.\d+.sq/tap86-sq/' \
    | cut -f1-2 -d '-')
  short_prefix=$(echo "$prefix" | perl -pe 's/\d+$// unless /^2023/;s/\-\d+$//;')
  check=$(grep "$short_prefix" patterns.txt | head -1)
  if [ ! "$check" ]; then
    prefix=${prefix/\-*/} 
    check=$(grep "$prefix" patterns2.txt | head -1)
    if [ ! "$check" ]; then
      prefix='other'
    else
      prefix="${prefix}-xx"
    fi
  fi

  mkdir -p "$WORK_DIR/$prefix"

  # Create labeled tile
  label="$filename"
  tile="$WORK_DIR/$prefix/$filename"

  gm convert "$img" \
    -resize ${TILE_SIZE}x${TILE_SIZE} \  # preserve aspect
    -gravity center -extent ${TILE_SIZE}x${TILE_SIZE} \
    \( -size ${TILE_SIZE}x${LABEL_HEIGHT} \
       -background white -fill black -gravity center \
       -pointsize ${FONT_SIZE} label:"$label" \) \
    -append "$tile"
done

echo "📦 Creating montages per group..."
GROUP_MONTAGES=()
for group_dir in "$WORK_DIR"/*; do
  [ -d "$group_dir" ] || continue
  group=$(basename "$group_dir")
  label_img="$group_dir/__group_label__.png"
  output_img="$group_dir/panel_${group}.jpg"

  # Create group label
  convert -size ${TILE_SIZE}x${GROUP_LABEL_HEIGHT} \
    -background lightgray -fill black -gravity center \
    -pointsize 24 label:"Group: $group" "$label_img"

  # Build montage of group images
  gm montage -geometry ${TILE_SIZE}x$((TILE_SIZE + LABEL_HEIGHT))+$SPACING+$SPACING \
    "$group_dir"/*.jpg "$group_dir"/*.jpeg \
    -tile x -background white "$group_dir/__grid__.jpg"

  # Prepend label to montage
  convert "$label_img" "$group_dir/__grid__.jpg" -append "$output_img"
  GROUP_MONTAGES+=("$output_img")
done

echo "🧱 Creating full mosaic..."
gm montage -geometry +${SPACING}+${SPACING} -background white \
  "${GROUP_MONTAGES[@]}" -tile 1x "$FINAL_IMAGE"

echo "🌀 Tiling with VIPS..."
vips dzsave "$FINAL_IMAGE" "$OUTPUT_DZI_DIR"
echo "✅ All done! DZI tiles in $OUTPUT_DZI_DIR"
