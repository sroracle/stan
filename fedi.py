#!/usr/bin/env python3
# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019 Max Rees
# See LICENSE for more information.
import html.parser # HTMLParser
import random      # choice
import sqlite3     # connect
import sys         # argv, exit
from pathlib import Path

from mastodon import Mastodon as Fedi

from markov import markov, chain_from_none

class TakeADump(html.parser.HTMLParser):
    def __init__(self, feed, **kwargs):
        super().__init__(**kwargs)
        self.data = []
        self.in_mention = False
        self.feed(feed)

    def handle_starttag(self, tag, attrs):
        attrs = [(i, k) for i, j in attrs for k in j.split()]
        if tag == "a" and ("class", "mention") in attrs:
            self.in_mention = True

    def handle_data(self, data):
        if not self.in_mention:
            self.data += data.split()

    def handle_endtag(self, tag):
        if tag == "a":
            self.in_mention = False

def generate_post(fedi, db, seed_post, reply=False):
    seed = TakeADump(seed_post.content).data
    if seed:
        seed = random.choice(seed).encode("utf-8", errors="replace")
    else:
        seed = random.choice(chain_from_none(db))

    if reply:
        mention = b"@" + seed_post.account.username.encode("utf-8") + b" "
        fedi.status_post(mention + markov(db, seed), in_reply_to_id=seed_post)
    else:
        fedi.status_post(markov(db, seed))

fedi = Fedi(
    access_token="data/fedi_user.cfg",
    api_base_url=sys.argv[1],
)
brain = f"file:{sys.argv[2]}?mode=ro"
db = sqlite3.connect(brain, uri=True)

since_f = Path("data/fedi_last_note")
try:
    since = since_f.read_text().strip()
    since = int(since)
except (FileNotFoundError, ValueError):
    since = None

notes = fedi.notifications(since_id=since)
for note in notes:
    if note.type != "mention":
        continue

    generate_post(fedi, db, note.status, reply=True)

if notes:
    since_f.write_text(str(notes[0].id))

if sys.argv[3] == "reply_only":
    sys.exit(0)

last_post = fedi.timeline_public(limit=1)[0]
generate_post(fedi, db, last_post)
