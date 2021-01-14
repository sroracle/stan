# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_cmd == "uptime" {
	irc_say(util_get_output("uptime"))
	next
}
