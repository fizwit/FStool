#!/bin/bash

BASEDIR=/data/fstool/
LocalLIB=$LOCALLIB:$BASEDIR/sbin/lib

if [ -z PERL5LIB ]; then
  export PERL5LIB=$LocalLIB:$PERL5LIB
  #echo PERL5LIB=$PERL5LIB
else
  export PERLLIB=$LocalLIB:$PERLLIB
  #echo PERLLIB=$PERLLIB
fi

./getconf.pl
