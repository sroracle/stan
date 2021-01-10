# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_msg ~ CMD_PATTERN"police( |$)" {
	if (irc_msgv[2] == "ON")
		POLICE = "ON"
	else if (irc_msgv[2] == "OFF")
		POLICE = "OFF"
	else if (irc_msgv[2] == "ON_FULLPOWER")
		POLICE = "ON_FULLPOWER"

	if (POLICE == "")
		POLICE = "OFF"

	irc_say(irc_channel, "POLICE:" POLICE)
	next
}
