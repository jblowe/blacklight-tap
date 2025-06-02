#!/usr/bin/env bash

export LC_ALL=C

python parse_box_filenames.py ../tap-solr-data/box-files.csv tmp
awk 'BEGIN{FS=OFS="\t"} {t=$18; $18=$2; $2=t; print} ' tmp | perl -pe 's/\r//g' > ../tap-solr-data/TAP_box.csv 
perl -i -pe 's/\r//;s/KEYTERMS_s/KEYTERMS_ss/' ../tap-solr-data/TAP_box.csv
perl -i -n  addtitle.pl ../tap-solr-data/TAP_box.csv
rm tmp
