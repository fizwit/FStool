load data LOCAL infile '/work/users/deyjohn/fsData/DB-scripts/load-uid.csv'
into table fsdata.UID 
fields terminated by ',' OPTIONALLY enclosed by '"'     
lines terminated by '\n' (uid, uname, GCOS, stat);

