#!/usr/bin/env python
"""
markov3.py - Markov Chains Library v3
Author: Seth Rees, www.sthrs.me
"""
import random, sys, re, random

# Constants
length = 30
punctuation = '(\S.+?[.!?])(?=\s+|$)'
end = '\n'

def main(max = 35, context=''):
   # Random size
   #max = random.choice(range(3, max + 1))

   # Temporaries
   chain = ['']
   alpha = beta = end
   tableau = {}

   # Build tableau
   brain = open('txt.txt', 'r')
   thoughts = brain.read().splitlines()
   for thought in thoughts:
      for word in thought.split():
         tableau.setdefault((alpha, beta), []).append(word)
         alpha, beta = beta, word
   tableau.setdefault((alpha, beta), []).append(end)
   brain.close()

   # Check for relevancy
   if context:
      words = context.lower().split()
      random.shuffle(words)

      # XXX debug
      print words

      answers = []

      keys = tableau.keys()
      random.shuffle(keys)
      for key in keys:
         if key[0].lower() in words or key[1].lower() in words:
            answers.append(key)

         else:
            for value in tableau[key]:
               if value.lower() in words:
                  answers.append(key)
      if answers:
         answer = random.choice(answers)

      else:
         answer = random.choice(tableau.keys())

   else:
      answer = random.choice(tableau.keys())

   alpha = answer[0]
   beta = answer[1]
   
   for i in range(0, max + 1):
      gamma = random.choice(tableau[(alpha, beta)])
      # XXX
      if gamma == end:
         print '*** WARNING: GAMMA IS END ***'
         continue

      chain.append(gamma)
      alpha, beta = beta, gamma

   chain = " ".join(chain).strip()

   sentences = []
   search = re.findall(punctuation, chain)
   if search and len(search) > 1:
      for sentence in search:
         if len(sentence) >= 15 and len(sentences) >= 2:
            pass

         else:
            sentences.append(sentence)

      sentences = ' '.join(sentences)
      chain = sentences

   return chain

if __name__ == '__main__':
   out = main(context=' '.join(sys.argv[1:]))
   print out