cd /mnt/images
tar xzf /mnt/images/dzi_$1_files.tgz 
ln -s /mnt/images/dzi_$1_files /var/www/html/tap/dzi_$1_files
ln -s /mnt/images/dzi_$1.dzi /var/www/html/tap/dzi_$1.dzi

