# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

$2 == "JOIN" && irc_channel == "#sporks" && irc_nick == "joe" {
	irc_say("boj")
}

$2 == "QUIT" && irc_nick == "joe" {
	irc_tell("#sporks", "eoj")
}
