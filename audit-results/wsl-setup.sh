set -e
rm -rf ~/audit && mkdir -p ~/audit/src ~/audit/lib
cd /mnt/c/programming_pj/r_textualize
tar --exclude=.git --exclude=audit-results --exclude=site --exclude=docs --exclude=pkgdown -cf - . | tar -xf - -C ~/audit/src
cd ~/audit
R CMD INSTALL --library=$HOME/audit/lib src > install.log 2>&1 && tail -3 install.log
