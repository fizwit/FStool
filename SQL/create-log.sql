/*
 *  fsData
 *
 *  2009.05.26  john dey
 *  2010.04.21
 *  create database for FS Tools State Information
 *
 *  Keep track of each data collection run 
 *  A record is created for each new "walk" collection
 *  This info is used to keep track of histic FS data colletion
 *  and to be used as a tool to manage out of date data.
 *
 *  FStype values 'user' or 'date'
 *  active values 'yes', 'no', 'protect'
 */
 CREATE TABLE `event-log` (
  `host`   char(8) default NULL,
  `source` char(12) default NULL,
  `volume` char(80) default NULL,
  `table`  char(30) default NULL,
  `start`  datetime default NULL,
  `end`    datetime default NULL,
  `state`  char(8)
);
