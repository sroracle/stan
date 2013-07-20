#!/usr/bin/env python3
# coding=utf-8
"""
calc.py - Phenny Calculator Module
Copyright 2008, Sean B. Palmer, inamidst.com
Licensed under the Eiffel Forum License 2.

http://inamidst.com/phenny/
"""

import re, urllib.request, sys

r_result = re.compile(r'(?i)<A NAME=results>(.*?)</A>')
r_tag = re.compile(r'<\S+.*?>')

subs = [
   (' in ', ' -> '),
   (' to ', ' -> '),
   (' as ', ' -> '),
   (' over ', ' / '), 
   ('AU', 'au'),
   ('£', 'GBP '), 
   ('€', 'EUR '), 
   ('\$', 'USD '), 
   ('KB', 'kilobytes'),
   ('lb', 'pound'),
   ('lbs', 'pounds'),
   ('MB', 'megabytes'),
   ('GB(?!P)', 'gigabytes'),
   ('TB', 'terabytes'),
   ('kbps', '(kilobits / second)'), 
   ('mbps', '(megabits / second)')
]

def calc(input): 
   """
   {0}calc <expression...> - Use the Frink online calculator.
   For commands, expressions, and examples, see http://futureboy.us/frinkdocs
   """
   q = ' '.join(input).strip()
   if not q: 
      return 'See http://futureboy.us/frinkdocs/'

   query = q[:]
   for a, b in subs: 
      query = re.sub(a, b, query)
   query = query.rstrip(' \t')

   precision = 5
   if query[-3:] in ('GBP', 'USD', 'EUR', 'NOK'): 
      precision = 2
   query = urllib.request.quote(query.encode('utf-8'))

   uri = 'http://futureboy.homeip.net/fsp/frink.fsp?fromVal='
   bytes = urllib.request.urlopen(uri + query).read().decode()
   m = r_result.search(bytes)
   if m: 
      result = m.group(1)
      result = r_tag.sub('', result) # strip span.warning tags
      result = result.replace('&gt;', '>')
      result = result.replace('(undefined symbol)', '(?) ')

      if '.' in result: 
         try: result = str(round(float(result), precision))
         except ValueError: pass

      if not result.strip(): 
         result = '?'
      elif ' in ' in q: 
         result += ' ' + q.split(' in ', 1)[1]

      return q + ' = ' + result[:350]
   else: return "Sorry, can't calculate that."

if len(sys.argv) > 1:
   print(calc(sys.argv[1:]))
else:
   print(calc(''))
