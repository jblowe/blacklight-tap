#!/usr/bin/env bash

ORIGINALfile="$(pwd)/$1"
RESULTfile="$(pwd)/$2"
rm -f ${RESULTfile}.csv ${RESULTfile}-other.csv

function check_type() {
  case "$1" in
 "TIFF image")
  T="image"
  ;;
  "JPEG image")
  T="image"
  ;;
  "PDF document")
  T="pdf"
  ;;
  "GIF image")
  T="image"
  ;;
  "Adobe Photoshop")
  T="pdf"
  ;;
  "PNG image")
  T="image"
  ;;
  "PostScript document")
  T="pdf"
  ;;
  "Canon CR2")
  T="image"
  ;;
  "Composite Document")
  T="image"
  ;;
  "Microsoft Word")
  T="document"
  ;;
  "Rich Text")
  T="document"
  ;;
  "ASCII text")
  T="document"
  ;;
  "Zip archive")
  T="document"
  ;;
  "Microsoft Excel")
  T="document"
  ;;
  "Microsoft PowerPoint")
  T="document"
  ;;
  "ISO-8859 text")
  T="document"
  ;;
  "FoxBase+/dBase III")
  T="other"
  ;;
  "Canon CR2")
  T="document"
  ;;
  "XML 1.0")
  T="document"
  ;;
  "Unicode text")
  T="document"
  ;;
  "MPEG sequence")
  T="other"
  ;;
  "CSV text")
  T="document"
  ;;
  *)
  T="other"
  ;;
 esac
}

while IFS=$'\t' read -r SOURCE ID FILENAME ORIGINAL TYPE SIZE
do
  ((LINES++))
  # extract and set filenames and directory paths for input and output
  F=$(basename "${ORIGINAL}")
  F2=${F%.*}
  F2=$(slugify "$F2")
  ((COUNTER++))
  TYPE2=$(echo "$TYPE" | perl -pe "s|^(\w+) (\w+).*|\1 \2|")
  TYPE=$(echo "$TYPE" | perl -pe 's/[^[:ascii:]]//g')
  #echo "type=$TYPE2"
  check_type "${TYPE2}"
  if [ $T != 'other' ]; then
    echo -e "${COUNTER}\t$T\t$SOURCE\t${F2}.thumb.jpg\t$FILENAME\t${ORIGINAL}\t${TYPE}\t${SIZE}" >> ${RESULTfile}.csv
  else
    echo -e "${COUNTER}\t$T\t$SOURCE\t${F2}.thumb.jpg\t$FILENAME\t${ORIGINAL}\t${TYPE}\t${SIZE}" >> ${RESULTfile}-other.csv
  fi
done <  "${ORIGINALfile}"

echo "${LINES} lines read from ${ORIGINALfile}"

