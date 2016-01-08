#!/bin/bash
#
source /etc/profile.d/modules.sh
module load perl/5.10.1

export PERLLIB=$PERLLIB:/data/fstool/sbin/
cd /data/fstool/sbin
/data/fstool/sbin/Batch.pl >/data/fstool/log/Batch.log 2>&1
