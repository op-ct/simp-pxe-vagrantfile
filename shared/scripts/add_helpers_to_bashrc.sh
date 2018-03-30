#!/bin/bash

modulepath=/etc/puppetlabs/code/environments/simp/modules
hieradatapath=/etc/puppetlabs/code/environments/simp/hieradata
echo "modulepath=${modulepath}" >> /root/.bashrc
echo "hieradatapath=${hieradatapath}" >> /root/.bashrc
echo "ppm=${modulepath}" >> /root/.bashrc
echo "ppms=${modulepath}/site" >> /root/.bashrc
echo "pph=${hieradatapath}" >> /root/.bashrc
echo "pphh=${hieradatapath}/hosts" >> /root/.bashrc
echo "pphg=${hieradatapath}/hostgroups" >> /root/.bashrc

