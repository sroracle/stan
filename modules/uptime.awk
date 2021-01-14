# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_msgv[1] == CMD_PREFIX"uptime" {
	irc_say(util_get_output("uptime"))
	next
}
