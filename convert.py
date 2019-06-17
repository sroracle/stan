#!/usr/bin/env python3
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

conn.execute("""
CREATE TABLE brain (
    keyword TEXT,
    chain TEXT
);
"""
)

conn.execute("CREATE INDEX brain_keyword ON brain(keyword);")

with conn, open(brain_filename, "r", errors="ignore") as brainfile:
    for line in brainfile:
        splitline = line.split(" ", 1)
        keyword = splitline[0]
        chains = splitline[1]
        splitchains = chains.split('\035')

        for chain in splitchains:
            try:
                conn.execute("INSERT INTO brain (keyword, chain) VALUES (?, ?);", (keyword, chain))
            except sqlite3.IntegrityError as e:
                pass

print("Done.")

