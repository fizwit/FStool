/*
 *  fsData
 *
 *  2013.11.05  john dey
 *  create database for configuration information 
 *  sites is a table of all sites (hosts) that can run fstools
 *   Each site has a full insall of fstool,  
 */
 CREATE TABLE `conf` (
  `site`         char(6), 
  `fs_key`       char(30) default NULL,
  `fs_value`     char(30) default NULL,
  PRIMARY KEY (fs_key),
  INDEX `site`
 ); 
