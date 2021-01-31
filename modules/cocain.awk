# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

BEGIN {
	HELP["cocain"] = CMD_PREFIX"cocain [NICK]: make fun of someone in the channel"
}

irc_cmd == "cocain" {
	if (irc_msgv[2])
		_cocain_target = irc_msgv[2]
	else
		_cocain_target = irc_rand_nick(irc_channel)

	irc_say("i fucking hate "_cocain_target". i bet they cnt evil lift many miligram of cocain with penis")
	next
}
