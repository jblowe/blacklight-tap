#!/usr/bin/env bash

export LC_ALL=C

python parse_box_filenames.py ../tap-solr-data/box-files.csv tmp
awk 'BEGIN{FS=OFS="\t"} {t=$18; $18=$2; $2=t; print} ' tmp > ../tap-solr-data/box-files.csv
python3 assign_keyterms.py ../tap-solr-data/TAP_box.csv tmp; mv tmp ../tap-solr-data/TAP_box.csv
