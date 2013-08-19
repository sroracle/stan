#!/usr/bin/env python3
import sys, time
from datetime import timedelta

if len(sys.argv) < 2:
   sys.exit(1)
nick = sys.argv[1]
db = {}

with open('data/seen.db', 'r') as f:
   for line in f.readlines():
      h, k = line.split()
      if h == nick:
         now = int(time.time())
         k = int(k)
         delta = timedelta(seconds=(now - k))
         k = time.gmtime(k)
         k = time.strftime('%a %b %d %Y %I:%M:%S %p %Z', k)
         print('I last saw {0} on {1} ({2} ago)'.format(h, k, delta))
         sys.exit(0)
print('I have never seen {0}.'.format(nick))
