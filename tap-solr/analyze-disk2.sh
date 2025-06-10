#!/usr/bin/env bash

THISPWD=$(pwd)
echo "pwd = $THISPWD"

ORIGINALfile="$THISPWD/$1"
rm -f $THISPWD/$3-filestats.csv

cd "$2"

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
  echo -e "${COUNTER}\t${F}\t${ORIGINAL}\t${STATS}\t${STATS2}" >> $THISPWD/$3-filestats.csv
done <  ${ORIGINALfile}

echo "${LINES} lines read from ${ORIGINALfile}"
echo "${COUNTER} file stats output to $3-filestats.csv"

