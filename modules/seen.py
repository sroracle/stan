#!/usr/bin/env python3
import sys, time

if len(sys.argv) < 2:
   sys.exit(1)
nick = sys.argv[1]
db = {}

with open('data/seen.db', 'r') as f:
   for line in f.readlines():
      h, k = line.split()
      if h == nick:
         k = time.localtime(int(k))
         k = time.strftime('%a %b %d %Y %I:%M:%S %p %Z', k)
         print('I last saw {0} on {1}'.format(h, k))
         sys.exit(0)
print('I have never seen {0}.'.format(nick))
