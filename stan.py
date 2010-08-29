#!/usr/bin/env python
"""
stan.py - Stan Kudzu, the markov chains bot
Author: Seth Rees, www.sthrs.me
"""
import socket, time, re, markov, os, random
from config import *

fobj = open('txt.txt')
m = markov.Markov(fobj)
fobj.close()
irc = socket.socket()
irc.connect((server, port))
irc.send("NICK %s\n" % nickname)
irc.send("USER stan %s /dev/null :Stan Kudzu\n" % nickname)
scanner = r":(\S+)!\S+@(\S+) (\S+) (\S+) :(.+)"
scan = re.compile(scanner)
say = lambda msg: irc.send('PRIVMSG %s :%s\n' % (origin, msg))   
msg = say
convos = {}
connected = True
while connected:
   recv = irc.recv(1024)
   if not recv:
      connected = False
      break
   recv = recv.splitlines()
   for line in recv:
      print line
      args = line.split()
      if line.startswith("PING"):
         # Respond to pings
         irc.send("PONG %s\n" % args[1][1:])
         continue
      if "376 %s :" % nickname in line:
         # Identify
         irc.send('PRIVMSG NickServ :identify %s\n' % password)
      if "266 %s :" % nickname in line:
         # Join channels
         if isinstance(channel, tuple) or isinstance(channel, list):
            for chan in channel:
               try: irc.send("JOIN %s\n" % chan)
               except: pass
         else:
            try: irc.send("JOIN %s\n" % channel)
            except: pass
      find = scan.search(line)
      if find:
         nick = find.group(1)
         mask = find.group(2)
         event = find.group(3)
         origin = find.group(4)
         text = find.group(5).strip()
         buff = text.split()
         sentence = ""
         if text.startswith("Stan: die") or text.startswith("Stan: piss off") and nick == owner:
            irc.send('QUIT :I spent an interesting evening recently with a grain of salt.\n')
            connected = False
            break
         elif text.startswith("Stan: reload") and nick == owner:
            say("Sir, yes sir! <o")
            fobj = open("txt.txt")
            m = markov.Markov(fobj)
            fobj.close()
            continue
         if nick not in convos:
            if nickname.lower() not in text.lower():
               # Decide whether to randomly say something or not
               choice = random.randint(3,20)
               if choice != 2 and choice != 4:
                  continue
            else:
               convos[nick] = time.time()
               sentence += nick + ": "
         else:
            ct = time.time()
            d = ct - convos[nick] 
            if d <= 10:
               sentence += nick + ": "
               convos[nick] = time.time()
            else:
               del convos[nick]
         length = random.randint(1, 10)
         sentence += m.generate_markov_text(length)
         sentence = sentence.strip()
         say(sentence)
while not connected:
   raw_input('\nDisconnected!')
   exit(1)