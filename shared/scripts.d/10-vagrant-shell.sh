#!/bin/sh

ppdir=/etc/puppetlabs/code/environments/production
vgdir=/vagrant

rsync -av --chown=root:puppet --chmod=u=rwX,g=rX "$vgdir/site" "$ppdir/"
rsync -av --chown=root:puppet --chmod=u=rwX,g=rX "$vgdir/data" "$ppdir/"
rsync -av --chown=root:root  "$vgdir/root/" "/root/"

for i in /root/.bashrc.*; do
  line="source $i"
  if ! grep "^${line}" /root/.bashrc &> /dev/null; then
    echo "source $i" >> /root/.bashrc
  fi
done

#echo 'profile::tftpboot::ip: 192.168.103.7' >> "$ppdir"/data/default.yaml

for cmd in chown chmod chcon; do
  ${cmd} -R --reference="$ppdir" "$ppdir/site" "$ppdir/data"
done

