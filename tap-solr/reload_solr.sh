#!/usr/bin/env bash

set -x

export LC_ALL=C

ss="http://localhost:8983/solr/tap/update/csv?commit=true&header=true&separator=%09&f.KEYTERMS_ss.split=true&f.KEYTERMS_ss.separator=|"

curl -S -s "http://localhost:8983/solr/tap/update" --data '<delete><query>*:*</query></delete>' -H 'Content-type:text/xml; charset=utf-8'
curl -S -s "http://localhost:8983/solr/tap/update" --data '<commit/>' -H 'Content-type:text/xml; charset=utf-8'

time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP86_photolog.csv -H 'Content-type:text/plain; charset=utf-8'
time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP90_photolog.csv -H 'Content-type:text/plain; charset=utf-8'
time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP92_photolog.csv -H 'Content-type:text/plain; charset=utf-8'
time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP94_photolog.csv -H 'Content-type:text/plain; charset=utf-8'

time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP86_bags.csv -H 'Content-type:text/plain; charset=utf-8'
time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP90_bags.csv -H 'Content-type:text/plain; charset=utf-8'
time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP92_bags.csv -H 'Content-type:text/plain; charset=utf-8'
time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP94_bags.csv -H 'Content-type:text/plain; charset=utf-8'

time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP_master.csv -H 'Content-type:text/plain; charset=utf-8'
time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP_images.csv -H 'Content-type:text/plain; charset=utf-8'
time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP_box.csv -H 'Content-type:text/plain; charset=utf-8'
time curl -X POST -S -s "$ss" -T ../tap-solr-data/TAP_trays.csv -H 'Content-type:text/plain; charset=utf-8'

# create the 'merged records'
python3 merge_images.py ../tap-solr-data/TAP_merged.csv
python3 assign_keyterms.py ../tap-solr-data/TAP_merged.csv tmp
mv tmp ../tap-solr-data/TAP_merged.csv

time curl -X POST -S -s "http://localhost:8983/solr/tap/update/csv?commit=true&header=true&separator=%09&f.DTYPES_ONLY_ss.split=true&f.DTYPES_ONLY_ss.separator=|&f.DTYPES_ss.split=true&f.DTYPES_ss.separator=|&f.RECORDS_ss.split=true&f.RECORDS_ss.separator=|&f.FILENAMES_ss.split=true&f.FILENAMES_ss.separator=|&f.IMAGES_ss.split=true&f.IMAGES_ss.separator=|&f.KEYTERMS_ss.split=true&f.KEYTERMS_ss.separator=|" -T ../tap-solr-data/TAP_merged.csv -H 'Content-type:text/plain; charset=utf-8'
python evaluate.py ../tap-solr-data/TAP_merged.csv /dev/null
