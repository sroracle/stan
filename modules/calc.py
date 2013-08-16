#!/usr/bin/env python3
# Copyright 2013, Sean B. Palmer, inamidst.com
# rewritten by Maxwell Rees, sthrs.me
# Licensed under the Eiffel Forum License 2.
import re, urllib.request, sys, codecs
sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')

# Constants
help = 'See http://futureboy.us/frinkdocs/'
uri = 'http://futureboy.homeip.net/fsp/frink.fsp?hideHelp=1&fromVal='
r_result = re.compile(r'(?i)<A NAME=results>(.*?)</A>')
r_tag = re.compile(r'<\S+.*?>')
subs = [
   ('AU', 'au'),
   ('\$', 'USD '), 
   ('KB', 'kilobytes'),
   ('lb', 'pound'),
   ('lbs', 'pounds'),
   ('MB', 'megabytes'),
   ('GB(?!P)', 'gigabytes'),
   ('TB', 'terabytes'),
   ('kbps', '(kilobits / second)'), 
   ('mbps', '(megabits / second)'),
   ('fl oz', 'floz'),
   ('fl_oz', 'floz')
]

# Argument retrieval
if len(sys.argv) < 1:
   print(help)
args = sys.argv[1:]
args = ' '.join(args).strip()
if not args:
   print(help)

# Query parsing
query = args[:]
for a, b in subs:
   query = re.sub(a, b, query)
query = query.rstrip(' \t')
query = urllib.request.quote(query.encode('utf-8'))

# Scrape result
scrape = urllib.request.urlopen(uri + query).read().decode()
result = r_result.search(scrape)
if result:
   result = result.group(1)
   result = r_tag.sub('', result)
   result = result.replace('&gt;', '>')
   result = result.replace('(undefined symbol)', '(?) ')
   if not result.strip():
      result = '?'
   print(args + ' = ' + result[:350])
else:
   print("Sorry, can't calculate that.")
