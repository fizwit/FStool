#  create initial fsdata base and create one user

create database fsdata;
grant ALL PRIVILEGES on fsdata.* to 'fsuser'@'localhost' identified by 'mypasswd' ;
grant ALL PRIVILEGES on fsdata.* to 'fsuser'@'%' identified by 'mypasswd' ;

CREATE TABLE  dataTable (
    `inode` bigint(20) default NULL,
    `uid` bigint(20) default NULL,
    `gid` bigint(20) default NULL,
    `size` bigint(20) default NULL,
    `blks` bigint(20) default NULL,
    `mode` bigint(20) default NULL,
    `atime` bigint(10) default 0,
    `mtime` bigint(10) default 0,
    `ctime` bigint(10) default 0,
    `fname` text,
    `extension` text,
    `cnt` int default NULL,
    `dirSz` bigint(12) NULL,
    `treeSz` bigint(20) NULL,
    `treeCnt` int default NULL,
    KEY `uid` (`uid`),
    KEY `gid` (`gid`),
    KEY `inode` (`inode`)
); 

load data LOCAL infile  '/admin/scripts/fsdata/src/walk.d/output'  
   into table dataTable
   fields terminated by ',' OPTIONALLY enclosed by '"'
   lines terminated by '\n' 
   (inode, fname, extension, uid, gid, size, blks, 
   mode, atime, mtime, ctime, cnt, dirSz, treeSz );
