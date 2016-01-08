/*
 *  fsData
 *
 *  2013.11.05  john dey
 *  create database for sites 
 *  sites is a table of all sites (hosts) that can run fstools
 *   Each site has a full insall of fstool,  
 */
 CREATE TABLE `sites` (
  `site` char(6) default NULL,
  `site_desc` char(30) default NULL,
  `sourcedir` varchar(128) default NULL,
  `host`      char(30) default NULL,  /* uname -n */ 
  `type`      char(12) default NULL,
  `webdir`    varchar(128) default NULL,
  `managed`   char(3)  default 'yes',  /* yes, no */
  primary key (site)
 ); 
