# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_msg ~ "^\001ACTION balefires .*\001$" {
	sub(/\001ACTION balefires /, "", irc_msg)
	sub(/\001$/, "", irc_msg)
	if ((irc_channel, irc_msg) in IRC_NAMES)
		irc_say(irc_msg, "Sorry, you stopped existing a few minutes ago. Please sit down and be quiet until you are woven into the pattern again.")
	next
}
