/*
 *  fsData
 *
 *  2013.11.05  john dey
 *  create database for volomes 
 *  volumes is a table of all file system object to be managed 
 */
 CREATE TABLE `volumes` (
  `site` char(6) default NULL,
  `vname` char(20) default NULL,
  `table_name` char(28) default NULL, /* YYMMDD_tag_[data|user] */
  `array`      char(16) default NULL,
  `group`      char(30) default NULL,  /* imaging, Molecular Profiling, informatics, */
  `owner`      char(30) default NULL,
  `comment`    char(80) default NULL,
  `path`       varchar(256) default NULL,
  `alias`      varchar(256) default NULL,
  `snap`       char(3)  default 'no',   -- does the volume have .snapshot directories?
  `managed`    char(3)  default 'yes',  /* yes, no */
  primary key (site, vname)
 ); 
