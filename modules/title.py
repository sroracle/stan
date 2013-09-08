#!/usr/bin/env python3
# Copyright 2008, Sean B. Palmer, inamidst.com
# rewritten by Maxwell Rees, sthrs.me 
# Licensed under the Eiffel Forum License 2.
import re, urllib.request, urllib.parse, sys, codecs, html.parser, json
sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')

key = 'AIzaSyA-4_hHDK2_r2VPRB2bSqinvMKP4pX6ZcQ'
r_uri = r'.*(https?://[^<> "\x01]+)[,.]?'
r_title = re.compile(r'(?ims)<title[^>]*>(.*?)</title\s*>')
r_entity = re.compile(r'&[A-Za-z0-9#]+;')
uri = sys.argv[1]

if 'youtube.com' in uri or 'youtu.be' in uri:
   vid = urllib.parse.urlparse(uri)
   if 'youtube.com' in uri:
      vid = urllib.parse.parse_qs(vid.query)['v'][0]
   if 'youtu.be' in uri:
      vid = vid.path[1:]
   request = 'https://www.googleapis.com/youtube/v3/videos?key={0}&part=snippet,statistics&fields=items(snippet,statistics)&id={1}'.format(key, vid)
   result = json.loads(urllib.request.urlopen(request).read().decode())
   result = result['items'][0]
   title = result['snippet']['title']
   views = int(result['statistics']['viewCount'])
   likes = int(result['statistics']['likeCount'])
   dislikes = int(result['statistics']['dislikeCount'])
   rating = (likes - dislikes) / (likes + dislikes)
   print('\02Title\02: {0}, \02Views\02: {1:,}, \02Rating\02: {2:.2%}'.format(title, views, rating))
   sys.exit(0)

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
   h = html.parser.HTMLParser()
   title = h.unescape(title)
   if not title: 
      # No title
      sys.exit(5)
   title = title.replace('\n', '')
   title = title.replace('\r', '')
   print('\02Title:\02', title)
