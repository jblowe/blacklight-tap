#!/usr/bin/env bash

# parse all 'base' data: photologs, imagenames, bag logs, inventories, Box files
./solr_bags.sh
./solr_photologs.sh
./solr_box.sh

python3 parseimagenames.py  ../tap-solr-data/images.csv ../tap-solr-data/TAP_images.csv
# perl -n parseimagenames.pl < ../tap-solr-data/images.csv > ../tap-solr-data/TAP_images.csv
perl -i -n  addtitle.pl ../tap-solr-data/TAP_images.csv

# add the UPM inventory records
cp ../tap-solr-data/tray_contents.csv ../tap-solr-data/TAP_trays.csv
perl -i -pe 's/SITENAME/SITE/;s/Huai Yai/HY/;s/Nil Kam Haeng/NKH/;s/Non Khok Wa/NKW/;s/Non Mak La/NML/;s/Non Pa Wai/NPW/;' ../tap-solr-data/TAP_trays.csv
perl -i -n  addtitle.pl ../tap-solr-data/TAP_trays.csv

# now load them into solr
./reload_solr.sh
