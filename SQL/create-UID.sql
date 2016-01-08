/*
 *  fsData
 *
 *  2009.05.26  john dey
 *  create database for inode FS data
 *  Create DB for UID historic data
 */
 CREATE TABLE `UID` (
  `uid` int unsigned default NULL,
  `uname` char(15) default NULL,
  `GCOS` char(40) default NULL,
  `email` char(40) default NULL,
  `manager` char(30) default NULL,
  `stat` bool , 
  KEY `uid` (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 MAX_ROWS=1000 ;
