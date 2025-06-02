ORIGINALfile="$(pwd)/$1"
rm -f ~/TAP/TAP-analysis/converted.csv

cd /Volumes/VL2

while read -r ORIGINAL
do
  ((LINES++))
  # extract and set filenames and directory paths for input and output
  F=$(basename "${ORIGINAL}")
  F2=${F/.*/}
  F2=${F2// /_}
  D=$(dirname "${ORIGINAL}")
  STATS=$(file -b "${ORIGINAL}")
  ((COUNTER++))
  convert "${ORIGINAL}" -strip -quality 80 -thumbnail x360 ~/TAP/TAP-analysis/thumbnails/"${F2}.thumb.jpg"
  echo -e "${COUNTER}\t${F2}.thumb.jpg\t${STATS}\t${ORIGINAL}" >> ~/TAP/TAP-analysis/converted.csv
done <  ${ORIGINALfile}

cat converted.csv | perl -ne 'chomp;@x=split/\t/;$_=$x[1];tr/a-z/A-Z/;s/^([A-Z]+)[ _]*(\d+).*/\1\2/;s/ //g;s/^PL_.*/PL/;s/^PHULON.*/PL/;s/TAP2K8.*/TAP2K8/;s/^T_?\d+.*/TNOS/;s/^(NPW|NML|NKH).*/\1/;if (/^(NPW|NML|NKH|PL|TAP\d+)|TNOS/) {print "$_"} else {print "OTHER"}; print "\t".join("\t",@x)."\n"' > converted-by-site.csv


echo "${LINES} lines read from ${ORIGINALfile}"

