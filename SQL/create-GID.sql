/*
 *  fsData
 *
 *  2009.05.26  john dey
 *  create database for inode FS data
 *  Create DB for GID historic data
 */
 CREATE TABLE `GID` (
  `gid` int unsigned default NULL,
  `gidName` char(30) default NULL,
  `stat` bool , 
  KEY `gid` (`gid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=1000 ;
