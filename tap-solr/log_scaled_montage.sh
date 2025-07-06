#!/bin/bash

INPUT_LIST="$1"
TILE_WIDTH=600
TILE_HEIGHT=600
LABEL_HEIGHT=120
TILES_DIR="tiles"
CHUNKS_DIR="chunks"
PANELS_DIR="panels"
DZI_DIR="dzi_output"

rm -rf  "$TILES_DIR" "$CHUNKS_DIR" "$PANELS_DIR" "$DZI_DIR"
mkdir -p "$TILES_DIR" "$CHUNKS_DIR" "$PANELS_DIR" "$DZI_DIR"

# Step 1: Resize + label each image into a group folder
echo "🔹 Preprocessing and labeling images..."
while read -r img; do
  base=$(basename "$img")
  prefix=$(echo "$base" | cut -c1 | tr '[:lower:]' '[:upper:]')
  prefix=$(echo "$base" \
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

  label=$(echo "$base" | tr -cd '[:alnum:]_.-')

  group_dir="$TILES_DIR/$prefix"
  mkdir -p "$group_dir"

  output="$group_dir/$base"
  tmp_image="/tmp/img_$$.jpeg"
  tmp_label="/tmp/lbl_$$.jpeg"

  gm convert "$img" \
    -resize "${TILE_WIDTH}x${TILE_HEIGHT}" \
    -background white -gravity center \
    -extent "${TILE_WIDTH}x${TILE_HEIGHT}" "$tmp_image"

  gm convert -size "${TILE_WIDTH}x${LABEL_HEIGHT}" \
    -background white -fill black \
    -gravity center -pointsize 60 \
    label:"$label" "$tmp_label"

  gm convert "$tmp_image" "$tmp_label" -append "$output"
done < "$INPUT_LIST"

# Step 2: Build montages with log-scaled layout
echo "🔹 Creating group montages with log-scaled layout..."
for group in "$TILES_DIR"/*; do
  prefix=$(basename "$group")

  # Collect all labeled files (.jpg, .jpeg, .JPG)
  images=( "$group"/*.jpg "$group"/*.jpeg "$group"/*.JPG )
  count=${#images[@]}
  if [ "$count" -eq 0 ]; then
    echo "⚠️  No images found for group $prefix"
    continue
  fi
  echo "  → $prefix group has $count images"

  # Calculate tile size using log scaling
  base=4
  scale=$(echo "l($count)/l(10)" | bc -l)
  size=$(echo "$base * $scale" | bc)
  size=$(printf "%.0f\n" "$size")
  [ "$size" -lt 4 ] && size=4
  [ "$size" -gt 20 ] && size=20

  tile_size="${size}x$size"
  chunk_size=$((size * size))

  chunk_dir="$CHUNKS_DIR/$prefix"
  mkdir -p "$chunk_dir"

  # Split into chunks
  split_dir=$(mktemp -d)
  printf "%s\n" "${images[@]}" > "$split_dir/list.txt"
  split -l $chunk_size "$split_dir/list.txt" "$split_dir/chunk_"

  chunk_num=1
  for f in "$split_dir"/chunk_*; do
    [ -s "$f" ] || continue
    chunk_file="$chunk_dir/chunk_${chunk_num}.jpeg"
    gm montage -geometry "${TILE_WIDTH}x$((TILE_HEIGHT + LABEL_HEIGHT))+5+5" -tile "$tile_size" @"$f" "$chunk_file"
    ((chunk_num++))
  done

  rm -r "$split_dir"
done

# Step 3: One panel per group (combine all chunks of that prefix)
echo "🔹 Assembling panels..."
for chunk_group in "$CHUNKS_DIR"/*; do
  prefix=$(basename "$chunk_group")
  chunk_imgs=( "$chunk_group"/*.jpeg )
  [ ${#chunk_imgs[@]} -eq 0 ] && continue
  output="$PANELS_DIR/panel_${prefix}.jpeg"

  echo "  → Assembling $prefix from ${#chunk_imgs[@]} chunks"
  gm montage -geometry "1x1+10+10" -tile "x1" "${chunk_imgs[@]}" "$output"
done

# Step 4: Deep Zoom for each panel
echo "🔹 Tiling with VIPS..."
for panel in "$PANELS_DIR"/*.jpeg; do
  name=$(basename "$panel" .jpeg)
  outdir="$DZI_DIR/$name"
  mkdir -p "$outdir"
  vips dzsave "$panel" "$outdir/$name" \
    --layout dz --suffix .jpeg[Q=90] --tile-size 256
done

echo "✅ All done! DZI tiles in $DZI_DIR/"
