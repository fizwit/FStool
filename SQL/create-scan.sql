/*
 *  fsData
 *
 *  2009.05.26  john dey
 *  create database for inode FS data
 *  Create DB for UID historic data
 */
 CREATE TABLE `scan` (
  `array` char(15) default NULL,
  `volume` char(40) default NULL,
  `tag` char(20) default NULL,
  `table_name` char(32) default NULL, /* YYMMDD_tag_[data|user] */
  `walk_start` datetime default NULL, 
  `walk_end` datetime default NULL,
  `walk_host` char(15) default NULL, /* name of host where walk runs */
  `state` char(10) default NULL, /* scanning complete dropped */
  `file_cnt` int default NULL,              /* file count */ 
  `vol_sizeB` bigint(20) default NULL, /* Volume size bytes */
  `dfsize`  bigint(15) default NULL,   /* df -k value */
  `dfavail` bigint(15) default NULL,   /* df -k value */
  `dfused`  bigint(15) default NULL,
  `deltaCNT` int default NULL,
  `deltaSize` bigint(15) default NULL
);
