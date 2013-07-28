#!/usr/bin/env python
 
import sys
import random
length = random.choice(range(1,9) + 4*range(10,21) + range(21,26))
class Markov:
   def __init__(self):
      self.h = {}
   def add( self, x, y ):
      if x not in self.h:
         self.h[x] = {}
      if y not in self.h[x]:
         self.h[x][y] = 0
      self.h[x][y] = self.h[x][y] + 1
   def next( self, x ):
      total = 0
      for k in self.h[x]:
         total = total + self.h[x][k]
      r = random.randint( 0, total -1 )
      i = 0
      for k in self.h[x]:
         i = i + self.h[x][k]
         if r < i:
            return k
if __name__ == '__main__':
   markov = Markov()
   for line in sys.stdin.readlines():
      line = line.rstrip("\n")
      ( x, y ) = line.split()
      markov.add( x, y )
   i = 0
   n = "the"
   if len(sys.argv) > 1:
      n = sys.argv[1]
   while i < length:
      try: n = markov.next( n )
      except: n = markov.next("the")
      print n,
      i = i + 1
