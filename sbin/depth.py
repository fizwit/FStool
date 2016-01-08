#!/usr/bin/env python

#  02.18.2014 john dey

import yaml
import MySQLdb

stream = file('../etc/FSconfig.yaml', 'r')
conf = yaml.load(stream)

db = MySQLdb.connect(host=conf['DBhost'],
                     user=  conf['DBusername'],
                     passwd = conf['DBpasswd'],
                     db = conf['DBname'] )

cur = db.cursor()

cur.execute( "show tables" )

numrows = int(cur.rowcount)
for row in range(0,numrows):
    row = cur.fetchone()
    print row[0]

cur.close()
db.close()
