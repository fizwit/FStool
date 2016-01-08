
#
# FStools local configuration
#
    url     => 'http://ryzabbix.merck.com/fsdata/CTCB',
    WEBdir  => '/SFS/www/fsdata',
    WEBbase => '/fsdata',
    FSbase  => '/data/fstool',
    csvDir  => '/data/fstool/fsdata',
    logDir  => '/data/fstool/log',
    pwalk   => '/data/fstool/bin/pwalk',
    sbin    => '/data/fstool/sbin',
    fsbatch => '/data/fstool/sbin/fsbatch.sh',

    Title     => 'Scientific Computing DevOps (HPC) ',
    SubTitle  => 'File System Storage Reports',
    Sites => {
      CTCB   => 'Charlotte Cluster B Isilon2',
      BMB    => 'Boston GPFS Storage ',
      RYN    => 'Rahway GPFS Storage  ',
      WPP    => 'West Point GPFS Storage',
      KEN    => 'Kenilworth GPFS Storage',
    },

#
#  MySql Connection Information
#
    DBusername => 'fsuser',
    DBpasswd   => 'ypasswd',
    DBname     => 'sdata',
    DBhost     => 'ocalhost',

#
#  Reports
#
    CTCB_report  => 'yes',
    PieUserAmt   => 'no',
    PieUserCnt   => 'no',
    TableUID     => 'yes ',
    TableUIDlist => 'yes',
    TableFatCnt  => 'no ',
    TableFatSz   => 'no',
    TableHistSiz => 'yes',

