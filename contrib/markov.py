#!/usr/bin/env python2.7
import sys, random
m = random.choice(range(1,10) + 4*range(10,21) + range(21,26))
h = {}
def a(x, y):
   if x not in h: h[x] = {}
   if y not in h[x]: h[x][y] = 0
   h[x][y] += 1
def e(x):
   total = 0
   for k in h[x]:
      total += h[x][k]
   r = random.randint( 0, total -1 )
   i = 0
   for k in h[x]:
      i += h[x][k]
      if r < i: return k
for line in sys.stdin.readlines():
   line = line.rstrip("\n")
   (x, y) = line.split()
   a(x, y)
i = 0
n = "the"
if len(sys.argv) > 1: n = random.choice(sys.argv[1:])
while i < m:
   try: n = e(n)
   except: n = e("the")
   sys.stdout.write(n + " ")
   i = i + 1
