#!/usr/bin/env bash

export LC_ALL=C

awk -F$'\t' '{print $19,$16,$9,$3,$6,$4,$1,$12,$5,$2,$15,$7,$8,$10,$11,$13,$14,$17,$18}' OFS=$'\t' ../tap-solr-data/TAP86-photolog.txt > ../tap-solr-data/TAP86_photolog.csv
cut -f1,2,5,6,7,8,10,11,12,13,14,15,16,20,21 ../tap-solr-data/TAP90-photolog.txt > ../tap-solr-data/TAP90_photolog.csv
awk -F$'\t' '{print $12,$11,$7,92,$4,$3,$10,$9,$1,$14,"",$5,$6,$2}' OFS=$'\t' ../tap-solr-data/TAP92-photolog.txt | perl -pe 's/\r//g' >  ../tap-solr-data/TAP92_photolog.csv
cut -f1,2,5,6,7,8,10,12,13,14,15 ../tap-solr-data/TAP94-photolog.txt > ../tap-solr-data/TAP94_photolog.csv
# small repair to NML 94 photolog data
perl -i -pe 's/\ttap\t/\tNML\t/' ../tap-solr-data/TAP94_photolog.csv

iconv -f utf-8 -t utf-8 -c ../tap-solr-data/TAP86_photolog.csv > tmp; mv tmp ../tap-solr-data/TAP86_photolog.csv
iconv -f utf-8 -t utf-8 -c ../tap-solr-data/TAP90_photolog.csv > tmp; mv tmp ../tap-solr-data/TAP90_photolog.csv
iconv -f utf-8 -t utf-8 -c ../tap-solr-data/TAP92_photolog.csv > tmp; mv tmp ../tap-solr-data/TAP92_photolog.csv
iconv -f utf-8 -t utf-8 -c ../tap-solr-data/TAP94_photolog.csv > tmp; mv tmp ../tap-solr-data/TAP94_photolog.csv

# tidy up some stray characters, insert DYPTE, etc.
#perl -i -pe 's/\xf1//;s/\xcd//g;s/\x0b//g;s/\xca/ /g;s/\r//g;s/\.0+\t/\t/g;' ../tap-solr-data/TAP*_photolog.csv
# perl -i -p fix.pl ../tap-solr-data/TAP*_photolog.csv
perl -i -pe 's/\.0+\t/\t/g;s/\r//g;s/\xe6/ /g;s/\x0B//g;s/^/photologs\t/;s/(nml|nkh|npw)/uc($1)/e;' ../tap-solr-data/TAP*_photolog.csv
perl -i -pe 'if (/^photologs\tT_/) {s/_//g;s/\t/_s\t/g;s/$/_s/;s/photologs/DTYPE/;s/92/YEAR/;s/\t\t/\tREVISION_D_s\t/;}' ../tap-solr-data/TAP*_photolog.csv

python3 assign_keyterms.py ../tap-solr-data/TAP86_photolog.csv tmp; mv tmp ../tap-solr-data/TAP86_photolog.csv
python3 assign_keyterms.py ../tap-solr-data/TAP90_photolog.csv tmp; mv tmp ../tap-solr-data/TAP90_photolog.csv
python3 assign_keyterms.py ../tap-solr-data/TAP92_photolog.csv tmp; mv tmp ../tap-solr-data/TAP92_photolog.csv
python3 assign_keyterms.py ../tap-solr-data/TAP94_photolog.csv tmp; mv tmp ../tap-solr-data/TAP94_photolog.csv

perl    -pe 's/\r//g;s/^/master\t/;' ../tap-solr-data/TAP_Master_Bag_Log_TAP_Data_Base.txt > ../tap-solr-data/TAP_master.csv
perl -i -pe 'if (/^master\tTnumber/) {s/Tnumber/T/;s/Season/YEAR/;s/^master/DTYPE/;tr/a-z/A-Z/;s/\t/_s\t/g;s/$/_s/;}' ../tap-solr-data/TAP_master.csv
# fix date: 199x -> 9x
perl -i -ne '$i++;@x=split(/\t/,$_,-1);if ($i != 1){$x[4]=int($x[4])-1900};print join("\t",@x);' ../tap-solr-data/TAP_master.csv
iconv -f utf-8 -t utf-8 -c ../tap-solr-data/TAP_master.csv > tmp; mv tmp ../tap-solr-data/TAP_master.csv

python3 assign_keyterms.py ../tap-solr-data/TAP_master.csv tmp; mv tmp ../tap-solr-data/TAP_master.csv

