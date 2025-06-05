#!/usr/bin/env bash

# parse all 'base' data: photologs, imagenames, bag logs, inventories, Box files
./solr_bags.sh
./solr_photologs.sh
#./solr_box.sh

# photo archive
python3 parseimagenames.py  ../tap-solr-data/images.csv ../tap-solr-data/TAP_images.csv
python3 assign_keyterms.py ../tap-solr-data/TAP_images.csv tmp; mv tmp ../tap-solr-data/TAP_images.csv

# box files
python parse_box_filenames.py ../tap-solr-data/box-files.csv tmp
awk 'BEGIN{FS=OFS="\t"} {t=$18; $18=$2; $2=t; print} ' tmp > ../tap-solr-data/TAP_box.csv
python3 assign_keyterms.py ../tap-solr-data/TAP_box.csv tmp; mv tmp ../tap-solr-data/TAP_box.csv

# add the UPM inventory records
perl -pe 's/SITENAME/SITE/;s/Huai Yai/HY/;s/Nil Kam Haeng/NKH/;s/Non Khok Wa/NKW/;s/Non Mak La/NML/;s/Non Pa Wai/NPW/;' ../tap-solr-data/tray_contents.csv > ../tap-solr-data/TAP_trays.csv
python3 assign_keyterms.py ../tap-solr-data/TAP_trays.csv tmp; mv tmp ../tap-solr-data/TAP_trays.csv

# now load them into solr
./reload_solr.sh
