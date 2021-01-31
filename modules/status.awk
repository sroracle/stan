# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

BEGIN {
	HELP["status"] = CMD_PREFIX"status: show bot status information"
}

irc_cmd == "status" {
	irc_say("Child #"CHILD": "util_age()" old with "NR" messages read")
	next
}
