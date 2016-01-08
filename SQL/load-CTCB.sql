

load data LOCAL infile 'CTCB.csv'
  into table volumes
  fields terminated by ','  OPTIONALLY enclosed by '"' 
  lines terminated by '\n'
  (site, snap, vname, path, alias, array, owner, comment);
