#!/bin/bash

# 2014.05.08 john dey
# 2014.08.07 john dey

set -u   # uninitialized variables
base=/data/fstool

if [ $# -ne 1 ] ; then
   echo usage: $0 '[site code RHY, WP, KW, CTCB ]'
fi

dateStamp=`date +"%Y.%m.%dT%H:%M"`
csvdir=${base}/fsdata/$1
startf=${csvdir}/start
finishf=${csvdir}/finish
loadf=${csvdir}/loaded
log=${csvdir}/load.log


echo $dateStamp start update.sh >$log
if [ ! -d $csvdir ]; then
   echo "missing: $cvsdir" >>$log
   exit 1
else
   echo "Loading data from $csvdir"
fi

if [ $loadf -nt $startf  ]; then
   echo nothing to load >>$log
   exit 1
else
   echo Data collection more recent than last data load
fi
   
if [ $startf -nt $finishf ]; then
   echo $dateStamp No new data to load >>$log
   exit 1
else
   echo "Data Collection has Finished, Lets load the data"
fi
echo 

vname=''
rm update.log
echo Purge old tables
${base}/sbin/PurgeOld.pl

for csvfile in $csvdir/*.csv; do
   if [ $csvfile -nt $startf ]; then  # if data file is newer than start time
      foo=`basename $csvfile`
      vname=`echo $foo | sed 's/\..*//'`
      dateStamp=`date +"%Y.%m.%d %H:%M"`
      if [[ -f ${csvdir}/${vname}.loaded &&
                ${csvdir}/${vname}.loaded -ot $finishf ]]; then 
         # already loaded skip
         echo $dateStamp app=update.sh status=loaded file=$csvfile >>$log
         continue;
      fi
      echo $dateStamp app=update.sh load=$vname datafile=$csvfile >>$log
      /data/fstool/sbin/update.pl $1 $vname >>update.log 2>>update.err
      if [ $? -eq 0 ] ; then
          touch ${csvdir}/${vname}.loaded
      fi
   fi
done

dateStamp=`date +"%Y.%m.%d %H:%M"`
echo $dateStamp app=update.sh status=complete >>$log
touch $loadf
