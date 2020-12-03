#!/usr/bin/env python3
# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2020 Max Rees
# See LICENSE for more information.
import collections # deque
import random      # choice, randint
import sqlite3     # connect
import sys         # argv, exit, stdin, stdout
from pathlib import Path

def backtrack(db, seed):
    words = db.execute(
        """SELECT * FROM brain
        WHERE chain2 = ?
        ORDER BY RANDOM()
        LIMIT 1""",
        (seed,),
    ).fetchone()

    return words

def chain_from_seed(db, seed):
    words = db.execute(
        """SELECT chain1, chain2 FROM brain
        WHERE keyword = ?
        ORDER BY RANDOM()
        LIMIT 1""",
        (seed,),
    ).fetchone()

    return words

def chain_from_none(db):
    words = db.execute(
        """SELECT chain1, chain2 FROM brain
        WHERE rowid = (ABS(RANDOM()) % (SELECT (SELECT MAX(rowid) FROM brain) + 1))
        LIMIT 1;"""
    ).fetchone()

    return words

def new_chain(db, keyword, chain1, chain2):
    db.execute(
        "INSERT INTO brain(keyword, chain1, chain2) VALUES (?, ?, ?);",
        (keyword, chain1, chain2),
    )

def chain_from_ctx_or_none(db, context):
    words = None

    n = len(context) if context else None
    if n:
        i = random.randrange(0, n)
        seed = context[i]
        words = chain_from_seed(db, seed)

    if not words:
        words = chain_from_none(db)

    return words

def markov(db, seed, *, context=None):
    seed = seed.strip()
    original_seed = seed
    want_len = random.randint(1, 10)
    if want_len == 1:
        want_len = random.randint(1, 10)
    elif want_len == 10:
        want_len = random.randint(21, 26)
    else:
        want_len = random.randint(10, 21)

    backtrack_len = random.randint(1, want_len)
    sentence = []
    while len(sentence) <= backtrack_len:
        words = backtrack(db, seed)

        if not words:
            break

        words = list(words)
        if words[1] == None:
            del words[1]

        sentence = words + sentence[1:]
        seed = sentence[0]

    seed = original_seed
    end = False
    while len(sentence) <= want_len and not end:
        words = chain_from_seed(db, seed)

        if not words:
            words = chain_from_ctx_or_none(db, context)

        words = list(words)
        if words[0] == None:
            del words[0]

        sentence += words
        seed = sentence[-1]

        if seed.endswith(b"\036"):
            sentence[-1] = seed[:-1]
            end = True

    sentence = b" ".join(sentence)
    return sentence

def speak(db, seed, context):
    while not seed:
        seed = chain_from_ctx_or_none(db, context)[0]

    sentence = markov(db, seed, context=context)

    if b"\x01ACTION" in sentence:
        sentence = sentence.split(b"\x01ACTION")
        sentence[0].strip()
        sentence[0] = b"PRIVMSG %b :%b\r\n" % (recipient, sentence[0])
        sys.stdout.buffer.write(sentence[0])

        for i in sentence[1:]:
            i = i.strip().replace(b"\x01", b"")
            i = b"PRIVMSG %b :\x01ACTION %b\x01\r\n" % (recipient, i)
            sys.stdout.buffer.write(i)

    else:
        sentence = b"PRIVMSG %b :%b\r\n" % (recipient, sentence)
        sys.stdout.buffer.write(sentence)

    sys.stdout.flush()

def learn(db, line):
    length = len(line)
    if length < 2:
        return
    print("*** Learning...", file=sys.stderr)

    if length < 3:
        return new_chain(db, line[0], None, line[1])

    for i in range(0, length - 2):
        if i + 1 > length - 2:
            end = b"\036"
        else:
            end = b""

        new_chain(db, line[i], line[i + 1], line[i + 2] + end)

    db.commit()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)

    brain = sys.argv[1]
    context = collections.deque(maxlen=16)

    if not Path(brain).exists():
        sys.exit(1)

    db = sqlite3.connect(brain)

    sys.stdin = open(
        sys.stdin.fileno(), mode="rb",
    )

    for line in sys.stdin:
        line = line.strip().split(b" ")

        if len(line) < 2:
            continue
        elif len(line) == 2:
            trigger, recipient = line
            seed = chain_from_ctx_or_none(db, context)[0]
        elif len(line) == 3:
            trigger, recipient, seed = line
        else:
            trigger, recipient = line[0:2]
            seed = random.choice(line[2:])

        context.extend(line[2:])
        trigger = int(trigger)
        if trigger == 0:
            continue

        if trigger == 1:
            learn(db, line[2:])

        elif trigger == 2:
            speak(db, seed, context)
