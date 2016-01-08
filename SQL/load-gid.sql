load data LOCAL infile '/tmp/gid-data.csv' into table fsdata.GID fields terminated by ',' OPTIONALLY enclosed by '"'     lines terminated by '\n' (gid, gidName, stat);
Query OK, 120 rows affected (0.00 sec)
Records: 120  Deleted: 0  Skipped: 0  Warnings: 0

