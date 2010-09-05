#!/usr/bin/env python
"""
markov2.py - Markov Chains Library v2
Author: Mixed
   ActiveState, www.activestate.com
   Seth Rees, www.sthrs.me
"""
import random, sys

def main(max=35, context=''):
   fobj = open("txt.txt")
   words = ['']
   nonword = "\n"
   w1 = nonword
   w2 = nonword
   table = {}
   # Get the words from the file and store them
   for line in fobj.read().split('\n'):
      for word in line.split():
         table.setdefault( (w1, w2), [] ).append(word)
         w1, w2 = w2, word
   table.setdefault( (w1, w2), [] ).append(nonword)
   # Look for context (if supplied) in the database
   # XXX Context Logic
   if context:
      w = context.split()
      answers = []
      for key in table.keys():
         if key[0].lower() in w or key[1].lower() in w:
            answers.append(key)
         else:
            for val in table[key]:
               if val.lower() in w:
                  answers.append(key)
      if answers:
         w = random.choice(answers)
      else:
         w = random.choice(table.keys())
   # Otherwise, just pick something random
   else:
      w = random.choice(table.keys())
   w1 = w[0]
   w2 = w[1]
   punct = ('.', '!', '?')
   rage = range(0, max + 1)
   for i in rage:
      newword = random.choice(table[(w1, w2)])
      if newword == nonword: break
      words.append(newword)
      w1, w2 = w2, newword
      # Keep going until we get punctuation
      # XXX Sentence Logic
      if i >= max and words[-1][-1] not in punct:
         rage.append(rage[-1] + 1)
   words = " ".join(words)
   words = words.strip()
   # Capitalize the first letter.
   # XXX Sentence Logic
   try: words = words[0].upper() + words[1:]
   except: return ''
   return words