scp -i ~/Downloads/jblowe.pem $1.html  ubuntu@54.71.209.160:/var/www/html/tap
tar czf dzi_$1_files.tgz dzi_$1_files
scp -i ~/Downloads/jblowe.pem dzi_$1_files.tgz  ubuntu@54.71.209.160:/mnt/images
rm dzi_$1_files.tgz
scp -i ~/Downloads/jblowe.pem dzi_$1.dzi  ubuntu@54.71.209.160:/mnt/images
