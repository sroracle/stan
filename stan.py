#!/usr/bin/env python
"""
stan.py - Stan Kudzu, the markov chains bot
Author: Seth Rees, www.sthrs.me
"""
import socket, time, re, markov2, os, random
from config import *

def sanatize(i):
   i = re.sub(r'[^\w]', ' ', i)
   return i

irc = socket.socket()
irc.connect((server, port))
irc.send("NICK %s\n" % nickname)
irc.send("USER stan %s /dev/null :Stan Kudzu\n" % nickname)
scanner = r":(\S+)!\S+@(\S+) (\S+) (\S+) :(.+)"
scan = re.compile(scanner)
say = lambda msg: irc.send('PRIVMSG %s :%s\n' % (origin, msg))   
msg = say
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
      if line.strip().startswith("PING"):
         # Respond to pings
         print args[1][1:]
         irc.send("\nPONG %s\n" % args[1][1:])
         continue
      if "376 %s :" % nickname in line:
         # Identify
         irc.send('PRIVMSG NickServ :identify %s\n' % password)
         time.sleep(1)
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
         if nick.lower() == "nickserv" or nick.lower() == "janusstats":
            continue
         mask = find.group(2)
         event = find.group(3)
         origin = find.group(4)
         text = find.group(5).strip()
         buff = text.split()
         sentence = ""
         if (text.startswith("Stan: die") or text.startswith("Stan: piss off")) and nick == owner:
            irc.send('QUIT :I spent an interesting evening recently with a grain of salt.\n')
            connected = False
            break
         if text.startswith("Stan: reload") and nick == owner:
            say('Yes, sir! <o')
            reload(markov2)
            continue
         else:
            if not origin.startswith("#"):
               print "Writing"
               fobj = open("txt.txt", "a")
               fobj.write(text + '\n')
               fobj.close()
               continue
            if not "stan" in text.lower():
               # Decide whether to randomly say something or not
               choice = random.randint(0,250)
               if choice != 42:
                  continue
            text = text.lower().replace('stan', '')
            text = sanatize(text)
            sentence += markov2.main(35, text)
            sentence = sentence.strip()
            say(sentence)
while not connected:
   raw_input('\nDisconnected!')
   exit(1)