#!/bin/bash

# set -xv
export LC_ALL=C

PWD="$(pwd)"
# nohup time ./analyze-disk1.sh
export TOP_DIRECTORY='/Users/johnlowe/Box Sync/TAP Collaborations'

# find "${TOP_DIRECTORY}" -type f | perl -ne 'print unless /\/\._/' | head -1000 > "${PWD}/box-files.csv"
find "${TOP_DIRECTORY}" -type f | perl -ne 'print unless /\/\._/' | grep -v DS_Store > "${PWD}/box-files.csv"

# nohup ./analyze-disk2.sh files-cleaned.txt

ORIGINALfile="$(PWD)/box-files.csv"
rm -f "${PWD}/box-files-stats.csv"

while read -r ORIGINAL
do
  ((LINES++))
  # extract and set filenames and directory paths for input and output
  F=$(basename "${ORIGINAL}")
  F2=${F/.*/}
  F2=${F2// /_}
  D=$(dirname "${ORIGINAL}")
  STATS=$(file -b "${ORIGINAL}")
  STATS2=$(stat -f "%z,%Sc,$Sm" -t "%Y/%m/%d %H:%M:%S" "${ORIGINAL}")
  ((COUNTER++))
  echo -e "${COUNTER}\t${F}\t${ORIGINAL}\t${STATS}\t${STATS2}" >> ${PWD}/box-files-stats.csv
done <  "${ORIGINALfile}"

echo "${LINES} lines read from ${ORIGINALfile}"
echo "${COUNTER} file stats output to box-file-stats.csv"

#cd "${PWD}"

exit

rm -rf box-thumbnails
mkdir box-thumbnails
cp placeholder.other.jpg box-thumbnails

# mkdir box-thumbnails/pdf
# mkdir box-thumbnails/image

# nohup time ./analyze-disk4.sh box-toconvert.filelist.csv box-thumbnails

for TYPE in image pdf
do
  mkdir box-thumbnails/${TYPE}
  if [[ "$TYPE" == 'pdf' ]]; then
    perl -ne 'print if /\.(PDF|PSD|AI)/i' box-files-stats.csv > box-${TYPE}-files-stats.csv
  else
    perl -ne 'print if /\.(JPE?G|TIFF?)/i' box-files-stats.csv > box-${TYPE}-files-stats.csv
  fi
  wc -l box-*-files-stats.csv
  perl -ne '@x = split /\t/;$f=$x[1];$f=~tr/a-z/A-Z/;print "$f\t$_" unless $seen{$f}++;' box-${TYPE}-files-stats.csv | perl -ne 'print unless /\/\./' > box-${TYPE}-toconvert.csv
  # cut -f3 box-${TYPE}-toconvert.csv| perl -pe 'tr/a-z/A-Z/;s/(^\w+ *\d+).*/\1/;s/ //g;s/^PL_.*/PL/;s/^PHULON.*/PL/;s/TAP2K8.*/TAP2K8/;s/^T\#?\d+.*/TNOS/;s/^(NPW|NML|NKH).*/\1/' | sort | uniq -c | sort -rn | head -30

  cut -f4 box-${TYPE}-toconvert.csv > "$(PWD)/box-${TYPE}-toconvert.filelist.csv"

  ORIGINALfile="$(PWD)/box-${TYPE}-toconvert.filelist.csv"
  RESULTfile="$(PWD)/box-${TYPE}-thumbnails"
  rm -f "${RESULTfile}.csv" "${RESULTfile}-by-site.csv"

  while read -r ORIGINAL
  do
    ((LINES++))
    # extract and set filenames and directory paths for input and output
    F=$(basename "${ORIGINAL}")
    F2=${F%.*}
    F2=${F2// /_}
    D=$(dirname "${ORIGINAL}")
    STATS=$(file -b "${ORIGINAL}")
    ((COUNTER++))
    # touch ${PWD}/box-thumbnails/"${F2}.thumb.jpg"
    XTYPE="${TYPE}"
    if [[ "$TYPE" == 'pdf' ]]; then
      magick "${ORIGINAL}[0-1]" -strip -quality 80 -thumbnail x360 -append ${PWD}/box-thumbnails/${TYPE}/"${F2}.${TYPE}.jpg" > /dev/null 2>&1
    elif [[ "$TYPE" == 'image' ]]; then
      magick "${ORIGINAL}" -strip -quality 80 -thumbnail x360 ${PWD}/box-thumbnails/${TYPE}/"${F2}.${TYPE}.jpg" > /dev/null 2>&1
    else
      # cp placeholder.thumbnail.jpg ${PWD}/box-thumbnails/"${F2}.other.jpg"
      F2='placeholder'
      XTYPE='other'
    fi
    echo -e "${COUNTER}\t${F2}.${XTYPE}.jpg\t${STATS}\t${ORIGINAL}\t${TYPE}" >> "${RESULTfile}.csv"
  done <  "${ORIGINALfile}"

  cat "${RESULTfile}.csv" | perl -ne 'chomp;@x=split/\t/;$_=$x[1];tr/a-z/A-Z/;s/^([A-Z]+)[ _]*(\d+).*/\1\2/;s/ //g;s/^PL_.*/PL/;s/^PHULON.*/PL/;s/TAP2K8.*/TAP2K8/;s/^T_?\d+.*/TNOS/;s/^(NPW|NML|NKH).*/\1/;if (/^(NPW|NML|NKH|PL|TAP\d+)|TNOS/) {print "$_"} else {print "OTHER"}; print "\t".join("\t",@x)."\n"' > "${RESULTfile}-by-site.csv"

  echo "${LINES} lines read from ${ORIGINALfile}"
  cut -f1 ${RESULTfile}-by-site.csv | sort | uniq -c | sort -rn | head
done

exit


# python analyze-disk5.py converted-by-site.csv moved.csv
