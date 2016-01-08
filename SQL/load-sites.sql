

load data LOCAL infile 'sites.csv'
  into table sites 
  fields terminated by ','  OPTIONALLY enclosed by '"' 
  lines terminated by '\n'
  (site, site_desc, sourcedir, host, type, webdir );
