#!/usr/bin/env bash

export LC_ALL=C

perl parsebaginfo.pl -s 86 < ../tap-solr-data/TAP86_bags.txt > ../tap-solr-data/TAP86_bags.csv
perl parsebaginfo.pl -s 90 < ../tap-solr-data/TAP90_Bags.txt > ../tap-solr-data/TAP90_bags.csv
perl parsebaginfo.pl -s 92 < ../tap-solr-data/TAP92_Bags_2K8-2.fp5FMPExpt_-_100408.txt > tmp
awk 'BEGIN{FS=OFS="\t"} {t=$6; $6=$2; $2=t; print} ' tmp > ../tap-solr-data/TAP92_bags.csv
rm tmp
perl parsebaginfo.pl -s 94 < ../tap-solr-data/TAP94_bags.txt > ../tap-solr-data/TAP94_bags.csv

python3 assign_keyterms.py ../tap-solr-data/TAP86_bags.csv tmp; mv tmp ../tap-solr-data/TAP86_bags.csv
python3 assign_keyterms.py ../tap-solr-data/TAP90_bags.csv tmp; mv tmp ../tap-solr-data/TAP90_bags.csv
python3 assign_keyterms.py ../tap-solr-data/TAP92_bags.csv tmp; mv tmp ../tap-solr-data/TAP92_bags.csv
python3 assign_keyterms.py ../tap-solr-data/TAP94_bags.csv tmp; mv tmp ../tap-solr-data/TAP94_bags.csv
