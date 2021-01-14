# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_msgv[1] == CMD_PREFIX"status" {
	irc_say(irc_channel, "Child #" CHILD ": " util_age() " old with " NR " messages read")
	next
}
