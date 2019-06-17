#!/usr/bin/env python3
# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019 Max Rees
# See LICENSE for more information.
import random  # choice, randint
import sqlite3 # connect
import sys     # argv, exit, stdin, stdout
from pathlib import Path

def chain_from_seed(db, seed):
    words = db.execute(
        """SELECT chain FROM brain
        WHERE keyword = ?
        ORDER BY RANDOM() LIMIT 1""",
        (seed,),
    ).fetchone()

    return words

def chain_from_none(db):
    words = db.execute(
        """SELECT chain FROM brain
        ORDER BY RANDOM() LIMIT 1""",
    ).fetchone()

    return words

def markov(db, seed):
    want_len = random.randint(1, 10)
    if want_len == 1:
        want_len = random.randint(1, 10)
    elif want_len == 10:
        want_len = random.randint(21, 26)
    else:
        want_len = random.randint(10, 21)

    sentence = []
    end = False
    while len(sentence) <= want_len and not end:
        words = chain_from_seed(db, seed)

        if not words:
            words = chain_from_none(db)

        words = words[0]
        sentence += words.split(" ")
        seed = sentence[-1]

        if seed.endswith("\036"):
            sentence[-1] = seed[:-1]
            end = True

    sentence = " ".join(sentence)
    return sentence

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)

    brain = sys.argv[1]

    if not Path(brain).exists():
        sys.exit(1)

    brain = f"file:{brain}?mode=ro"
    db = sqlite3.connect(brain, uri=True)

    sys.stdout = open(
        sys.stdout.fileno(), mode="w", buffering=1,
        encoding="utf-8", errors="replace",
    )

    for line in sys.stdin:
        line = line.rstrip("\n").split(" ")

        if len(line) < 1:
            continue
        elif len(line) == 1:
            recipient = line[0]
            seed = chain_from_none(db)[0]
        elif len(line) == 2:
            recipient, seed = line
        else:
            recipient = line[0]
            seed = random.choice(line[1:])

        sentence = markov(db, seed)
        sentence = f"PRIVMSG {recipient} :{sentence}\r"
        print(sentence)
