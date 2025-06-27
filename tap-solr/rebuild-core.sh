#!/usr/bin/env bash

# parse all 'base' data: photologs, imagenames, bag logs, inventories, Box files
./solr_bags.sh
./solr_photologs.sh

# photo archive
python3 parseimagenames.py  ../tap-solr-data/media-converted.csv ../tap-solr-data/TAP_images.csv images
python3 assign_keyterms.py ../tap-solr-data/TAP_images.csv tmp; mv tmp ../tap-solr-data/TAP_images.csv

# box files
python parseimagenames.py ../tap-solr-data/box-files.csv tmp box
awk 'BEGIN{FS=OFS="\t"} {t=$18; $18=$2; $2=t; print} ' tmp > ../tap-solr-data/TAP_box.csv
python3 assign_keyterms.py ../tap-solr-data/TAP_box.csv tmp; mv tmp ../tap-solr-data/TAP_box.csv

# add the UPM inventory records
perl -pe 's/TAP//;s/SEASON/YEAR/;s/SITENAME/SITE/;s/Huai Yai/HY/;s/Nil Kam Haeng/NKH/;s/Non Khok Wa/NKW/;s/Non Mak La/NML/;s/Non Pa Wai/NPW/;' ../tap-solr-data/tray_contents.csv > ../tap-solr-data/TAP_trays.csv
python3 assign_keyterms.py ../tap-solr-data/TAP_trays.csv tmp; mv tmp ../tap-solr-data/TAP_trays.csv

# now load them into solr
./reload_solr.sh

# compute distribution of images and photologs
python check_rolls.py ../tap-solr-data/image-analysis.csv

