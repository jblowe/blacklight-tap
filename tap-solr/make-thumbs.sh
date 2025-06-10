#!/usr/bin/env bash

set -x

ORIGINALfile="$(pwd)/$1"
RESULTfile="$(pwd)/$2-converted.csv"
rm -f ${RESULTfile}

while IFS=$'\t' read -r ID TYPE SOURCE SLUG FILENAME ORIGINAL STAT SIZE
do
  ((LINES++))
  if [ $SOURCE == 'pla' ]; then
    DIR='/Volumes/VL2/'
  else
    DIR='/Users/johnlowe/Box Sync/TAP Collaborations'
  fi
  if [ $TYPE == 'image' ]; then
    magick -density 300 "$DIR/${ORIGINAL}" -background white -alpha remove -resize '1000x>' -strip -quality 100 ~/TAP/TAP-analysis/thumbnails/${TYPE}/${SLUG}
    echo -e "${ID}\t$T\t${TYPE}\t${SOURCE}\t${SLUG}\t${FILENAME}\t${ORIGINAL}\t${STAT}\t${SIZE}" >> ${RESULTfile}
  elif [ $TYPE == 'pdf' ]; then
    magick -density 300 "$DIR/${ORIGINAL}[0]" -resize 1000x -define png:compression-level=9 -strip -background white -alpha remove ~/TAP/TAP-analysis/thumbnails/${TYPE}/${SLUG}
    echo -e "${ID}\t$T\t${TYPE}\t${SOURCE}\t${SLUG}\t${FILENAME}\t${ORIGINAL}\t${STAT}\t${SIZE}" >> ${RESULTfile}
  else
    echo -e "${ID}\t$T\t${TYPE}\t${SOURCE}\tplaceholder.svg\t${FILENAME}\t${ORIGINAL}\t${STAT}\t${SIZE}" >> ${RESULTfile}
  fi
done <  "${ORIGINALfile}"

echo "${LINES} lines read from ${ORIGINALfile}"

