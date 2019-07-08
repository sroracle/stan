#!/usr/bin/env python3
# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019 Lee Starnes
# Copyright (c) 2019 Max Rees
# See LICENSE for more information.
import os
import sqlite3
import sys

brain_filename = "brain.db"
new_brain = "brain.sqlite"

if len(sys.argv) >= 2:
    brain_filename = sys.argv[1]
    if brain_filename == "-h" or brain_filename == "--help":
        print("Usage: {} [brain.db] [brain.sqlite]".format(sys.argv[0]))
        exit(0)
    if len(sys.argv) >= 3:
        new_brain = sys.argv[2]

if not os.path.exists(brain_filename):
    print("Error: Brain file {} doesn't exist.".format(brain_filename))
    exit(1)

if os.path.exists(new_brain):
    print("Error: {} already exists".format(new_brain))
    exit(1)

print("Converting old brain {} to sqlite3 brain {}...".format(brain_filename, new_brain))

conn = sqlite3.connect(new_brain)

conn.executescript("""
CREATE TABLE brain (
    keyword BLOB,
    chain1 BLOB,
    chain2 BLOB
);
CREATE INDEX brain_keyword ON brain(keyword);
CREATE INDEX brain_chain2 ON brain(chain2);
"""
)

with conn, open(brain_filename, "rb") as brainfile:
    for line in brainfile:
        line = line.split(b" ", maxsplit=1)
        keyword = line[0]
        chains = line[1].rstrip(b"\n").split(b"\035")

        for chain in chains:
            chain = chain.split(b" ", maxsplit=1)
            if len(chain) < 1:
                continue

            elif len(chain) == 1:
                chain.append(chain[0])
                chain[0] = None

            try:
                conn.execute(
                    "INSERT INTO brain(keyword, chain1, chain2) VALUES (?, ?, ?);",
                    (keyword, chain[0], chain[1])
                )
            except sqlite3.IntegrityError as e:
                print("Warning:", e)

print("Done.")
