#!/bin/bash

#  
#  Process pwalk data collected from remote sites
#  Remote sites run pwalk
#  ssh files to central server
#  run this on central server and check if there is new data to process
#  2015.10.05 john dey

if [ $# -eq 1 ]; then
  site=$1
else
  echo usage: $0 '<site code>'
  exit 1
fi

basedir='/data/fstool'
sbin=${basedir}/sbin
csvdir=${basedir}/fsdata/${site}
log=${csvdir}/process.log

if [ -e csvdir ] ; then
   echo $csvdir Does not exist
fi

start=${csvdir}/coll-start
finished=${csvdir}/coll-end
processed=${csvdir}/processed


# check for new data

date=`date +"%Y.%m.%dT%H:%M"`

if [ -e $processed ]; then  # Processed
   if [ $processed -nt $start ]; then  # nothing to do yet
      echo process is newer than coll-start, nothing to do>> $log
      exit 0
   else
      echo Collection started but not processed
   fi 
else
   echo No processing has been done
fi

# no processing 
if [ $start -nt $finished ]; then  
   echo Collection started but not finished, nothing to do >> $log
   exit 0
else
   echo Collection is finished
fi

# lets process some data
echo Data collection finished and newer than last processed
echo Run FSbatsh.sh  
${sbin}/FSbatch.sh $site



