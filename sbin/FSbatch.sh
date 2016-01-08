#!/bin/bash
#
#  2015 john dey
#
#  Run this fist from the master.
#  This program only builds a new script for loading data.
#  The loadscript is based on config files and availble CSV files.
#
#  Prereq: csv files need to have been generated and moved to ryzabbix
#
#  output: fsload.sh
#  Step to 2 run the output from this script to acc
#
source /etc/profile.d/modules.sh
module purge
module load perl/5.10.1

export PERLLIB=$PERLLIB:/data/fstool/sbin/
cd /data/fstool/sbin
/data/fstool/sbin/FSbatch.pl CTC-B >/data/fstool/log/FSbatch.log 2>&1
