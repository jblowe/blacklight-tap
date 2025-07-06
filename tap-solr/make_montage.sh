#!/bin/bash

set -e  # Exit on error

# CONFIGURATION
INPUT_DIR="input_images"
GROUP_DIR="grouped"
MONTAGE_DIR="montages"
FINAL_DIR="final_output"
THUMB_WIDTH=250
THUMB_HEIGHT=250
THUMB_PADDING=5
TILE_COLUMNS=40   # Images per row in each block

# PREP
mkdir -p "$GROUP_DIR" "$MONTAGE_DIR" "$FINAL_DIR"

echo "🔤 Grouping images by first prefix..."
for file in "$INPUT_DIR"/*.jpeg; do
  [[ -e "$file" ]] || continue
  prefix=$(basename "$file" | cut -c1-4 | tr '[:lower:]' '[:upper:]' | perl -pe 's/^86.*/86NN/;s/\-//g;s/^([A-Z]+)\d+/\1N/g;s/\.//g;')
  mkdir -p "$GROUP_DIR/$prefix"
  cp "$file" "$GROUP_DIR/$prefix/"
done

echo "🖼️ Creating labeled montages per group..."
shopt -s nullglob
for d in "$GROUP_DIR"/*; do
  prefix=$(basename "$d")
  out_montage="$MONTAGE_DIR/montage_${prefix}.jpeg"

  jpegs=("$d"/*.jpeg)
  if [ ${#jpegs[@]} -eq 0 ]; then
    echo "  ⚠️  Skipping $prefix — no images"
    continue
  fi

  num_files=${#jpegs[@]}
  rows=$(( (num_files + TILE_COLUMNS - 1) / TILE_COLUMNS ))
  tile="${TILE_COLUMNS}x${rows}"

  echo "  📚 $prefix — $num_files images, layout $tile"
  gm montage "${jpegs[@]}" \
    -label "%f" \
    -geometry "${THUMB_WIDTH}x${THUMB_HEIGHT}+${THUMB_PADDING}+${THUMB_PADDING}" \
    -tile "$tile" \
    "$out_montage"
done

echo "🔠 Adding section labels..."
for img in "$MONTAGE_DIR"/montage_*.jpeg; do
  prefix=$(basename "$img" .jpeg | sed 's/montage_//')
  label_img="$MONTAGE_DIR/label_${prefix}.jpeg"
  full_img="$FINAL_DIR/labeled_${prefix}.jpeg"

  montage_width=$(identify -format "%w" "$img")
  LABEL_HEIGHT=120

  gm convert -size ${montage_width}x${LABEL_HEIGHT} \
    -background white \
    -fill black \
    -gravity center \
    -pointsize 72 \
    label:"$prefix" \
    "$label_img"

  gm convert "$label_img" "$img" -append -quality 95 "$full_img"
done

echo "🧱 Stitching final montage..."
gm convert $(ls "$FINAL_DIR"/labeled_*.jpeg | sort) -append full_montage.jpeg

echo "✅ Done! Final output is: full_montage.jpeg"
