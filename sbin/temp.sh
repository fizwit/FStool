#!/bin/bash
#
# File: fsload.sh
# generated Tue Apr  7 00:16:09 2015
runLog=/data/fstool/log/fsload.log
LogDir=/data/fstool/log
source /etc/profile.d/modules.sh
module load perl/5.10.1
echo `date +"%Y.%m.%dT%H:%M"` state=start >$runLog 2>&1
export PERLLIB=$PERLLIB:/data/fstool/sbin/

 /data/fstool/sbin/fsreport.pl CTC-B SRS > $LogDir/SRS.log
 /data/fstool/sbin/fsreport.pl CTC-B data1 > $LogDir/data1.log
 /data/fstool/sbin/fsreport.pl CTC-B hdf5_prod > $LogDir/hdf5_prod.log 
 /data/fstool/sbin/fsreport.pl CTC-B home > $LogDir/home.log 
 /data/fstool/sbin/fsreport.pl CTC-B mpData > $LogDir/mpData.log 
 /data/fstool/sbin/fsreport.pl CTC-B omicsoft > $LogDir/omicsoft.log 
 /data/fstool/sbin/fsreport.pl CTC-B project > $LogDir/project.log 
 /data/fstool/sbin/fsreport.pl CTC-B store_prod > $LogDir/store_prod.log 
echo `date +"%Y.%m.%dT%H:%M"`, state=finished >>$runLog 2>&1
