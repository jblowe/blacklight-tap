#!/usr/bin/env bash

export LC_ALL=C

perl -pe 's/__//g;s/_\t/\t/g' ../tap-solr-data/TAP86-photolog.txt | cut -f1-19 | perl -pe 'print "86\t"' > ../tap-solr-data/TAP86_photolog.csv
cut -f1,2,5-8,10-16,20,21 ../tap-solr-data/TAP90-photolog.txt | perl -pe 'print "90\t"' > ../tap-solr-data/TAP90_photolog.csv
cut -f1-12,14 ../tap-solr-data/TAP92-photolog.txt | perl -pe 's/\r/ /g' | perl -pe 'print "92\t"' >  ../tap-solr-data/TAP92_photolog.csv
cut -f1-17 ../tap-solr-data/TAP94-photolog.txt | perl -pe 'print "94\t"' > ../tap-solr-data/TAP94_photolog.csv
# small repair to NML 94 photolog data
perl -i -pe 's/\ttap\t/\tNML\t/;s/REVISION_D\tDATE/REVISION_D\tDATE2/;' ../tap-solr-data/TAP94_photolog.csv

perl -i -pe 'if (/ROLL/ && /EXP/) {s/^\d+/SEASON/;s/_//g;}' ../tap-solr-data/TAP*_photolog.csv

# tidy up some stray characters, insert DYPTE, etc.
#perl -i -pe 's/\xf1//;s/\xcd//g;s/\x0b//g;s/\xca/ /g;s/\r//g;s/\.0+\t/\t/g;' ../tap-solr-data/TAP*_photolog.csv
# perl -i -p fix.pl ../tap-solr-data/TAP*_photolog.csv
perl -i -pe 's/"//g;s/\t0\.0+\t/\t0\t/g;s/\.0+\t/\t/g;s/\r//g;s/\xe6/ /g;s/\xca/ /g;s/\x0b//g;s/^/photologs\t/;s/(nml|nkh|npw)/uc($1)/e;' ../tap-solr-data/TAP*_photolog.csv
# fix up header
perl -i -pe 'if (/ROLL/ && /EXP/) {s/_//g;s/\t/_s\t/g;s/$/_s/;s/photologs/DTYPE/;}' ../tap-solr-data/TAP*_photolog.csv

iconv -f utf-8 -t utf-8 -c ../tap-solr-data/TAP86_photolog.csv > tmp; mv tmp ../tap-solr-data/TAP86_photolog.csv
iconv -f utf-8 -t utf-8 -c ../tap-solr-data/TAP90_photolog.csv > tmp; mv tmp ../tap-solr-data/TAP90_photolog.csv
iconv -f utf-8 -t utf-8 -c ../tap-solr-data/TAP92_photolog.csv > tmp; mv tmp ../tap-solr-data/TAP92_photolog.csv
iconv -f utf-8 -t utf-8 -c ../tap-solr-data/TAP94_photolog.csv > tmp; mv tmp ../tap-solr-data/TAP94_photolog.csv

python3 assign_keyterms.py ../tap-solr-data/TAP86_photolog.csv tmp; mv tmp ../tap-solr-data/TAP86_photolog.csv
python3 assign_keyterms.py ../tap-solr-data/TAP90_photolog.csv tmp; mv tmp ../tap-solr-data/TAP90_photolog.csv
python3 assign_keyterms.py ../tap-solr-data/TAP92_photolog.csv tmp; mv tmp ../tap-solr-data/TAP92_photolog.csv
python3 assign_keyterms.py ../tap-solr-data/TAP94_photolog.csv tmp; mv tmp ../tap-solr-data/TAP94_photolog.csv

perl    -pe 's/\r//g;s/^/master\t/;' ../tap-solr-data/TAP_Master_Bag_Log_TAP_Data_Base.txt > ../tap-solr-data/TAP_master.csv
perl -i -pe 'if (/^master\tTnumber/) {s/Tnumber/T/;s/Season/YEAR/;s/^master/DTYPE/;tr/a-z/A-Z/;s/\t/_s\t/g;s/$/_s/;}' ../tap-solr-data/TAP_master.csv
# fix date: 199x -> 9x
perl -i -ne '$i++;@x=split(/\t/,$_,-1);if ($i != 1 && $x[4]>0){$x[4]=int($x[4])-1900};print join("\t",@x);' ../tap-solr-data/TAP_master.csv
iconv -f utf-8 -t utf-8 -c ../tap-solr-data/TAP_master.csv > tmp; mv tmp ../tap-solr-data/TAP_master.csv

python3 assign_keyterms.py ../tap-solr-data/TAP_master.csv tmp; mv tmp ../tap-solr-data/TAP_master.csv

