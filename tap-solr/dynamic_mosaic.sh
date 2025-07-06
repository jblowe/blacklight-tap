#!/usr/bin/env bash
set -euo pipefail
set -vx

# Configuration
MIN_TILE=600      # for biggest groups
MAX_TILE=1200     # for smallest groups
LABEL_HEIGHT=100
SPACING=10
INPUT_DIR="tiles_w_thumbnails"
OUTPUT_DIR="tiles_dynamic"
UPSCALED_DIR="upscaled_tiles_dynamic"
FINAL_MOSAIC="full_mosaic_dynamic.jpg"
DZI_OUTPUT="dzi_dynamic"
OVERLAY_METADATA="overlay_metadata.json"

rm -rf "$OUTPUT_DIR" "$UPSCALED_DIR"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$UPSCALED_DIR"

# Step 1: Count images in each group
group_dirs=()
group_counts=()
total_images=0
LOG_MAX=0

echo "Counting images in each group..."
for group_dir in "${INPUT_DIR}"/*; do
  [ -d "$group_dir" ] || continue
  count=$(find "$group_dir" -name '*.thumb.jpg' | wc -l | xargs)
  [ "$count" -gt 0 ] || continue
  group_dirs+=("$group_dir")
  group_counts+=("$count")
  total_images=$((total_images + count))

  log=$(awk -v c="$count" 'BEGIN { print log(c+1)/log(10) }')
  if awk -v l="$log" -v m="$LOG_MAX" 'BEGIN { exit !(l > m) }'; then
    LOG_MAX=$log
  fi
done

# Step 2: Compute dynamic tile sizes
group_tile_sizes=()
echo "Computing tile sizes..."
for i in "${!group_dirs[@]}"; do
  count="${group_counts[$i]}"
  log=$(awk -v c="$count" 'BEGIN { print log(c+1)/log(10) }')
  norm=$(awk -v l="$log" -v max="$LOG_MAX" 'BEGIN { print 1 - (l / max) }')
  tile_size=$(awk -v min=$MIN_TILE -v max=$MAX_TILE -v n="$norm" 'BEGIN { printf("%d", min + (max - min) * n) }')
  group_tile_sizes+=("$tile_size")
done

# Step 3: Build labeled tiles and group mosaics
> "$OVERLAY_METADATA"
echo "[" >> "$OVERLAY_METADATA"

x_offset=0
y_offset=0
across=25  # number of group blocks per row

for i in "${!group_dirs[@]}"; do
  group="${group_dirs[$i]}"
  tile_size="${group_tile_sizes[$i]}"
  echo "Processing group: $group with tile size: $tile_size"

  total_height=$((tile_size + LABEL_HEIGHT))
  mkdir -p "$group/tmp"
  labeled_images=()
  img_index=0

  for img in "$group"/*.thumb.jpg; do
    filename=$(basename "$img")
    base="${filename%.thumb.jpg}"
    resized_img="$group/tmp/${base}_resized.jpg"
    label_img="$group/tmp/${base}_label.jpg"
    labeled_img="$group/tmp/${base}_labeled.jpg"

    magick "$img" -resize "${tile_size}x${tile_size}" \
      -background white -gravity center -extent "${tile_size}x${tile_size}" "$resized_img"

    magick -density 150 -size ${tile_size}x${LABEL_HEIGHT} \
      -background white -fill black -gravity center -pointsize 20 \
      label:"$base" "$label_img"

    magick "$resized_img" "$label_img" -append "$labeled_img"
    labeled_images+=("$labeled_img")

    # Calculate position in the group grid
    grid_x=$((img_index % 10))
    grid_y=$((img_index / 10))
    abs_x=$((x_offset + grid_x * (tile_size + SPACING)))
    abs_y=$((y_offset + grid_y * (total_height + SPACING)))

    echo "  {\n    \"type\": \"image\",\n    \"bounds\": [$abs_x, $abs_y, $tile_size, $total_height],\n    \"link\": \"https://myserver.com/image/${base}\"\n  }," >> "$OVERLAY_METADATA"

    img_index=$((img_index + 1))
  done

  group_basename=$(basename "$group")
  grid_out="$UPSCALED_DIR/${group_basename}__grid__.jpg"
  vips arrayjoin "${labeled_images[*]}" "$grid_out" \
    --across 10 --background 255,255,255

  # Add group overlay region
  group_width=$((10 * (tile_size + SPACING)))
  group_height=$(( ((img_index + 9) / 10) * (total_height + SPACING) ))
  echo "  {\n    \"type\": \"group\",\n    \"bounds\": [$x_offset, $y_offset, $group_width, $group_height],\n    \"link\": \"https://myserver.com/group/${group_basename}\"\n  }," >> "$OVERLAY_METADATA"

  # Update offsets
  if (( (i + 1) % across == 0 )); then
    x_offset=0
    y_offset=$((y_offset + group_height + SPACING))
  else
    x_offset=$((x_offset + group_width + SPACING))
  fi

done

# Trim trailing comma and close JSON array
sed -i '' -e '$ s/},/}/' "$OVERLAY_METADATA"
echo "]" >> "$OVERLAY_METADATA"

# Step 4: Build full mosaic from group grids
echo "Creating full mosaic..."
gm montage -background white -geometry "+$SPACING+$SPACING" -tile ${across}x \
  "$UPSCALED_DIR"/*__grid__.jpg "$FINAL_MOSAIC"

# Step 5: Deep Zoom Image output
echo "Creating DZI tiles..."
vips dzsave "$FINAL_MOSAIC" "$DZI_OUTPUT" \
  --layout dz --tile-size 254 --overlap 1 --suffix ".jpg[Q=90]"

vips arrayjoin "$(find "$UPSCALED_DIR" -name '*__grid__.jpg' | sort)" full_mosaic.v \
  --across $across --hspacing $SPACING --vspacing $SPACING && \
vips dzsave full_mosaic.v "$DZI_OUTPUT" \
  --layout dz --tile-size 254 --overlap 1 --suffix ".jpg[Q=90]"




echo "✅ Done! Mosaic: $FINAL_MOSAIC, DZI tiles in $DZI_OUTPUT/, overlays in $OVERLAY_METADATA"
