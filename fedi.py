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

from markov import markov

class TakeADump(html.parser.HTMLParser):
    def __init__(self, feed, **kwargs):
        super().__init__(**kwargs)
        self.data = []
        self.feed(feed)

    def handle_data(self, data):
        self.data += data.split()

login = Fedi(
    access_token="data/fedi_user.cfg",
    api_base_url=sys.argv[1],
)

last_post = login.timeline_public(limit=1)[0]
last_post = last_post["content"].replace("\r", " ").replace("\n", " ")
last_post = TakeADump(last_post).data

if not Path(sys.argv[2]).exists():
    sys.exit(1)

brain = f"file:{sys.argv[2]}?mode=ro"
db = sqlite3.connect(brain, uri=True)
login.toot(markov(db, random.choice(last_post)))
