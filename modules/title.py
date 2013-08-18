#!/usr/bin/env python3
# Copyright 2008, Sean B. Palmer, inamidst.com
# rewritten by Maxwell Rees, sthrs.me 
# Licensed under the Eiffel Forum License 2.
import re, urllib, urllib.request, urllib.error, urllib.parse, http.client, urllib.parse, time
from html.entities import name2codepoint
import sys

r_uri = r'.*(https?://[^<> "\x01]+)[,.]?'
r_title = re.compile(r'(?ims)<title[^>]*>(.*?)</title\s*>')
r_entity = re.compile(r'&[A-Za-z0-9#]+;')
uri = sys.argv[1]

try: 
   redirects = 0
   while True: 
      info = urllib.request.urlopen(uri).info()
      if not isinstance(info, list): 
         status = '200'
      else: 
         status = str(info[1])
         info = info[0]
      if status.startswith('3'): 
         uri = urllib.parse.urljoin(uri, info['Location'])
      else: break
      redirects += 1
      if redirects >= 25: 
         # Too many redirects
         sys.exit(3)
   try: mime = info['content-type']
   except: 
      # No content-type
      sys.exit(2)
   if not (('/html' in mime) or ('/xhtml' in mime)): 
      # Not HTML
      sys.exit(4)
   scrape = urllib.request.urlopen(uri).read().decode()
except IOError as e:
   # Can't connect
   sys.exit(1)
m = r_title.search(scrape)
if m: 
   title = m.group(1)
   title = title.strip()
   title = title.replace('\t', ' ')
   title = title.replace('\r', ' ')
   title = title.replace('\n', ' ')
   while '  ' in title: 
      title = title.replace('  ', ' ')
   if len(title) > 200: 
      title = title[:200] + '[...]'
   def e(m): 
      entity = m.group(0)
      if entity.startswith('&#x'): 
         cp = int(entity[3:-1], 16)
         return chr(cp)
      elif entity.startswith('&#'): 
         cp = int(entity[2:-1])
         return chr(cp)
      else: 
         char = name2codepoint[entity[1:-1]]
         return chr(char)
   title = r_entity.sub(e, title)
   if not title: 
      # No title
      sys.exit(5)
   title = title.replace('\n', '')
   title = title.replace('\r', '')
   print('\02Title:\02', title)