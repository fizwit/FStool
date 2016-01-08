#!/bin/bash
#
# File: fsload.sh
# generated Fri Dec  4 11:46:04 2015
runLog=/data/fstool/log/fsload.log
LogDir=/data/fstool/log
source /etc/profile.d/modules.sh
module load perl/5.10.1
echo `date +"%Y.%m.%dT%H:%M"` state=start >$runLog 2>&1
export PERLLIB=$PERLLIB:/data/fstool/sbin/

# home 
(/data/fstool/sbin/update.pl --load CTC-B home.csv CTCB_home > $LogDir/home.log ;\
 /data/fstool/sbin/update.pl --index CTC-B home.csv CTCB_home >> $LogDir/home.log ;\
 /data/fstool/sbin/fsreport.pl CTC-B home >> $LogDir/home.log ;\
    /data/fstool/sbin/fsdetail.pl CTC-B home >> $LogDir/home.log ;\
)

echo `date +"%Y.%m.%dT%H:%M"`, state=finished >>$runLog 2>&1
