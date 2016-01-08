#!/bin/bash
#
# fastdu.bash
# generated Fri Jan  8 05:10:03 2016
runLog=/data/fstool/sbin/Batch.log
source /etc/profile.d/modules.sh
module load perl/5.10.1
echo `date +"%Y.%m.%dT%H:%M"` state=start >$runLog 2>&1
export PERLLIB=$PERLLIB:/data/fstool/sbin/

# 
# SiteCode=WPP Site=West Point GPFS Storage
#   group=safty
echo `date +"%Y.%m.%dT%H:%M"`, site=WPP >>$runLog 2>&1
