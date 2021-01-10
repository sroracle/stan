# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

$2 == "JOIN" && irc_channel == "#sporks" && irc_nick == "joe" {
	irc_say("#sporks", "boj")
}

$2 == "QUIT" && irc_nick == "joe" {
	irc_say("#sporks", "eoj")
}
