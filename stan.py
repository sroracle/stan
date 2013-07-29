#!/usr/bin/env python
"""
stan.py - Stan Kudzu, the markov chains bot
Author: Seth Rees, www.sthrs.me
"""
import socket, time, re, markov3, os, random
from config import *

def sanatize(i):
   i = re.sub(r'[^\w]', ' ', i)
   return i

def markov(text):
   text = text.lower().replace('stan3', '')
   text = sanatize(text)
   sentence = markov3.main(35, text)
   sentence = sentence.strip()
   time.sleep(3)
   say(sentence)

irc = socket.socket()
irc.connect((server, port))
irc.send("NICK %s\n" % nickname)
irc.send("USER stan %s /dev/null :Stan Kudzu\n" % nickname)
scanner = r":(\S+)!\S+@(\S+) (\S+) (\S+) :(.+)"
scan = re.compile(scanner)
stan = re.compile(r"(?i)^(.* |)stan([,: !?.]|)( |$).*")
say = lambda msg: irc.send('PRIVMSG %s :%s\n' % (origin, msg))
msg = say
if __name__ == "__main__":
   connected = True
else:
   connected = False
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
         irc.send("\nPONG %s\n" % args[1][1:])
         continue
      if "376 %s :" % nickname in line:
         # Identify
         irc.send('PRIVMSG NickServ :identify %s\n' % password)
         time.sleep(1)
      if "376 %s :" % nickname in line:
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
         if (text.lower().startswith("stan3: die") or text.lower().startswith("stan3: piss off")) and nick == owner:
            irc.send('QUIT :I spent an interesting evening recently with a grain of salt.\n')
            connected = False
            break
         if text.lower().startswith("stan3: reload") and nick == owner:
            say('Yes, sir! <o')
            reload(markov3)
            continue
         else:
            choice = random.choice(range(0, 10))
            if origin.startswith("#") and choice == 7:
               print "Writing"
               text = text.lower().replace('stan3:','').replace('stan3','')
               fobj = open("txt.txt", "a")
               fobj.write(text + '\n')
               fobj.close()
            if 'stan3' in text.lower():
               choice = 42
            else:
               upper = 250
               # Decide whether to randomly say something or not
               choice = random.randint(0,upper)
            if choice == 42:
               markov(text)
while not connected:
   raw_input('\nDisconnected!')
   exit(1)