cd /Volumes/VL2
find . -type f | perl -ne 'print unless /\/\._/' > ~/TAP/TAP-analysis/files.txt
grep -v "Mrs." files.txt | grep -v "Documents and Settings" | grep -v "Microsoft" | grep -v "ShapeFiles" | grep -v "Profiles" | grep -v ColorSync | grep -i -v "Alex" | grep -v FileMaker | grep -v Correspondence | grep -v Apple | grep -v Extensions | grep -v Trash | grep -v Installer | grep -v "System Folder" | grep -v Trip | grep -v "DS_Store" | grep -v "Thumb" | grep -v BkMain | grep -v "The Sims" | grep -v "\.ini" | grep -v -i family > files-cleaned.txt

