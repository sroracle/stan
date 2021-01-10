# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_msg ~ CMD_PATTERN"status$" {
	irc_say(irc_channel, "Child #" CHILD ": " util_age() " old with " NR " messages read")
	next
}
