# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_msg ~ CMD_PATTERN"cocain( |$)" {
	if (irc_msgv[2])
		_cocain_target = irc_msgv[2]
	else
		_cocain_target = irc_rand_nick(irc_channel)

	irc_say(irc_channel, "i fucking hate "_cocain_target". i bet they cnt evil lift many miligram of cocain with penis")
	next
}
