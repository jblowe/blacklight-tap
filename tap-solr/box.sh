find ~/Box\ Sync/TAP\ Collaborations/ -type f > box.txt
convert "/Users/johnlowe/Box Sync/TAP Collaborations//NPW/NPW 86 Sq A/NPW Sq A/NPW A Balk Section North.psd" output.jpg
convert "/Users/johnlowe/Box Sync/TAP Collaborations//NPW/NPW 86 Sq A/NPW Sq A/NPW A Balk Section North.psd[0]" output.jpg
rm output*
# cp "/Users/johnlowe/Box Sync/TAP Collaborations//NML/NML_Op_2/NML Op 2 - Notebook.pdf" .
perl -n parseimagenames.pl < box.txt > t_box.csv
# cp howto.txt box-analysis.sh
vi box-analysis.sh
