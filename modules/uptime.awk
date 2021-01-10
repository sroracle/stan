# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_msg ~ CMD_PATTERN"uptime$" {
	irc_say(irc_channel, util_get_output("uptime"))
	next
}
