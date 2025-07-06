#!/bin/bash

# vips_mosaic.sh
# Uses VIPS to create a giant zoomable mosaic of labeled images grouped by prefix
# Each image tile is square with label below, grouped by prefix with a block header

#set -euo pipefail
#set -vx

# === CONFIGURATION ===
INPUT_DIR="$1"
WORK_DIR="tiles_w_thumbnails"

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

  cp "$img" "$outdir"
done

echo "✅ Done!"

