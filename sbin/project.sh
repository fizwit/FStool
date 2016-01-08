#!/bin/bash
#
# /data/fstool/sbin/fsbatch.sh 
# generated Mon Jan  5 11:29:00 2015
runLog=/data/fstool/log/project.log
source /etc/profile.d/modules.sh
module load perl/5.10.1
echo `date +"%Y.%m.%dT%H:%M"` state=start >$runLog 2>&1
export PERLLIB=$PERLLIB:/data/fstool/sbin/

# 
echo `date +"%Y.%m.%dT%H:%M"`, store-prod=start >>$runLog 2>&1
(/data/fstool/sbin/update.pl --load CTC-B store-prod.csv CTCB_store_prod; \
  /data/fstool/sbin/update.pl --index CTC-B store-prod.csv CTCB_store_prod; \
  /data/fstool/sbin/fsreport.pl CTC-B store_prod; \
 ) &
echo `date +"%Y.%m.%dT%H:%M"`, store-prod=finished >>$runLog 2>&1
echo `date +"%Y.%m.%dT%H:%M"`, project=start>>$runLog 2>&1
(/data/fstool/sbin/update.pl --load CTC-B project.csv CTCB_project; \
  /data/fstool/sbin/update.pl --index CTC-B project.csv CTCB_project; \
  /data/fstool/sbin/fsreport.pl CTC-B project; \
    /data/fstool/sbin/fsdetail.pl CTC-B osd; \
    /data/fstool/sbin/fsdetail.pl CTC-B genomics; \
    /data/fstool/sbin/fsdetail.pl CTC-B gentools; \
    /data/fstool/sbin/fsdetail.pl CTC-B genome; \
    /data/fstool/sbin/fsdetail.pl CTC-B genetics; \
 ) &
echo `date +"%Y.%m.%dT%H:%M"`, project=finished >>$runLog 2>&1

