
export LC_ALL=C ; cut -f4 filestats.csv| cut -f1 -d "," | perl -pe 's/ length.*//;s/file version \-?\d+/file/;s/metric data.*/metric data/' | grep -v 'cannot open' | sort | uniq -c | perl -ne 'print unless /^ *1 /' | perl -pe 's/^ *(\d+) /\1\t/' > typesbytype.csv
sort -rn typesbytype.csv > typesbyfreq.csv

