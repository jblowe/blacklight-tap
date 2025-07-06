#!/bin/bash

# vips_mosaic.sh
# Uses VIPS to create a giant zoomable mosaic of labeled images grouped by prefix
# Each image tile is square with label below, grouped by prefix with a block header

#set -euo pipefail
set -vx

# === CONFIGURATION ===
INPUT_DIR="$1"
WORK_DIR="tiles"
OUTPUT_IMAGE="full_mosaic.jpg"
DZI_DIR="dzi_output"
TILE_SIZE=1200
LABEL_HEIGHT=100
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
echo "📁 Grouping and labeling images..."
find "$INPUT_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) | sort | while read -r img; do
  filename=$(basename "$img")
  prefix=$(echo "$filename" \
    | perl -pe 's/^(tk|tap|nkh|nml|npw)[- ](\d+)/\1\2/;s/ro-\d+.thumb/ro-999.thumb/;s/.thumb.jpe?g//;' \
    | perl -pe 's/^86.*/86x/;s/^(2023\d+).*/\1/;s/^img.*/img/i;s/sq\-(\w).*/sq\1/;s/\-([a-z])\-/-sq\1-/;s/(\-op)\-?(\d+).*/\1\2/;s/(nnt|kwpv).*/\1/;' \
    | perl -pe 's/ro-(\d)(\d\d).*/r\1/;s/ro?l?l?\-?(\d+)/r\1/;s/op\-/op/;s/^(op\w+)\-.*/\1/;s/t-phu-lon.*/phu-lon/;s/^t\-(\d)(\w+).*/tno\1/;' \
    | perl -pe 's/^scan.*/\scan/;s/^object.*/objects/;s/^tap86\-\d+$/tap86-xx/;s/pl\-\d+.*/pl-xx/;s/tap.86.\d+.sq/tap86-sq/' \
    | cut -f1-2 -d '-')
  # skip phu lon, for now
  if [[ $prefix == "pl"* ]]; then continue ; fi
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

  outdir="$WORK_DIR/$prefix"
  mkdir -p "$outdir"

  base="${filename%.thumb.jpg}"
  labeled_img="$outdir/${base}_labeled.jpg"
  tmp_resized="$outdir/tmp_resized.jpg"
  tmp_combined="$outdir/tmp_combined.jpg"
  label_img="$outdir/tmp_label.png"

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

# move the enormous 'other' folder out of tiles
mv tiles/other .

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

GROUP_BLOCKS=( tiles/*/__grid__.jpg )

# === FINAL MOSAIC ===
echo "🧩 Joining all group blocks into full mosaic..."

# --- Config ---
TILE_WIDTH=1200
TILE_HEIGHT=1400
SPACING=10
TILE_GEOMETRY="${TILE_WIDTH}x${TILE_HEIGHT}+${SPACING}+${SPACING}"
JPEG_QUALITY=95

# Create mosaic ---
echo "Creating high-res mosaic..."
gm montage -tile 30x -geometry "$TILE_GEOMETRY" tiles/*/__grid__.jpg "$OUTPUT_IMAGE"

# --- Step 3: Generate Deep Zoom tiles ---
echo "Generating DZI tiles..."
vips dzsave "$OUTPUT_IMAGE" "$DZI_DIR" \
  --layout dz \
  --tile-size 254 \
  --overlap 1 \
  --suffix .jpg[Q=$JPEG_QUALITY]

echo "✅ Done! OpenSeadragon viewer can now load $DZI_DIR.dzi"

