#!/bin/bash
#
# File: fsload.sh
# generated Mon Dec 21 19:20:11 2015
runLog=/data/fstool/log/fsload.log
LogDir=/data/fstool/log
source /etc/profile.d/modules.sh
module load perl/5.10.1
echo `date +"%Y.%m.%dT%H:%M"` state=start >$runLog 2>&1
export PERLLIB=$PERLLIB:/data/fstool/sbin/

# 
# SRS 
(/data/fstool/sbin/update.pl --load CTC-B SRS.csv CTCB_SRS > $LogDir/SRS.log ;\
 /data/fstool/sbin/update.pl --index CTC-B SRS.csv CTCB_SRS >> $LogDir/SRS.log ;\
 /data/fstool/sbin/fsreport.pl CTC-B SRS >> $LogDir/SRS.log ;\
    /data/fstool/sbin/fsdetail.pl CTC-B SRS >> $LogDir/SRS.log ;\
)
# data1 
(/data/fstool/sbin/update.pl --load CTC-B data1.csv CTCB_data1 > $LogDir/data1.log ;\
 /data/fstool/sbin/update.pl --index CTC-B data1.csv CTCB_data1 >> $LogDir/data1.log ;\
 /data/fstool/sbin/fsreport.pl CTC-B data1 >> $LogDir/data1.log ;\
)
# home 
(/data/fstool/sbin/update.pl --load CTC-B home.csv CTCB_home > $LogDir/home.log ;\
 /data/fstool/sbin/update.pl --index CTC-B home.csv CTCB_home >> $LogDir/home.log ;\
 /data/fstool/sbin/fsreport.pl CTC-B home >> $LogDir/home.log ;\
    /data/fstool/sbin/fsdetail.pl CTC-B home >> $LogDir/home.log ;\
)
# mpData 
(/data/fstool/sbin/update.pl --load CTC-B mpData.csv CTCB_mpData > $LogDir/mpData.log ;\
 /data/fstool/sbin/update.pl --index CTC-B mpData.csv CTCB_mpData >> $LogDir/mpData.log ;\
 /data/fstool/sbin/fsreport.pl CTC-B mpData >> $LogDir/mpData.log ;\
    /data/fstool/sbin/fsdetail.pl CTC-B mpData >> $LogDir/mpData.log ;\
)
# omicsoft 
(/data/fstool/sbin/update.pl --load CTC-B omicsoft.csv CTCB_omicsoft > $LogDir/omicsoft.log ;\
 /data/fstool/sbin/update.pl --index CTC-B omicsoft.csv CTCB_omicsoft >> $LogDir/omicsoft.log ;\
 /data/fstool/sbin/fsreport.pl CTC-B omicsoft >> $LogDir/omicsoft.log ;\
)
# project 
(/data/fstool/sbin/update.pl --load CTC-B project.csv CTCB_project > $LogDir/project.log ;\
 /data/fstool/sbin/update.pl --index CTC-B project.csv CTCB_project >> $LogDir/project.log ;\
 /data/fstool/sbin/fsreport.pl CTC-B project >> $LogDir/project.log ;\
    /data/fstool/sbin/fsdetail.pl CTC-B genetics >> $LogDir/project.log ;\
    /data/fstool/sbin/fsdetail.pl CTC-B genomics >> $LogDir/project.log ;\
    /data/fstool/sbin/fsdetail.pl CTC-B gentool >> $LogDir/project.log ;\
    /data/fstool/sbin/fsdetail.pl CTC-B omicsProj >> $LogDir/project.log ;\
    /data/fstool/sbin/fsdetail.pl CTC-B osd >> $LogDir/project.log ;\
) &
# scratch 
(/data/fstool/sbin/update.pl --load CTC-B scratch.csv CTCB_scratch > $LogDir/scratch.log ;\
 /data/fstool/sbin/update.pl --index CTC-B scratch.csv CTCB_scratch >> $LogDir/scratch.log ;\
 /data/fstool/sbin/fsreport.pl CTC-B scratch >> $LogDir/scratch.log ;\
)
echo `date +"%Y.%m.%dT%H:%M"`, state=finished >>$runLog 2>&1
