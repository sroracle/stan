# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_msg ~ "^\001ACTION balefires [^\001 ]+\001$" {
	sub("\001", "", $6)
	if ((irc_channel, $6) in IRC_NAMES)
		irc_say($6, "Sorry, you stopped existing a few minutes ago. Please sit down and be quiet until you are woven into the pattern again.")
	next
}
