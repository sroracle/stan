# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2021 Max Rees
# See LICENSE for more information.

function help(topic,        msg) {
	if (!(topic in HELP)) {
		msg = "Help topics: "
		for (topic in HELP)
			msg = msg topic", "
		sub(/, $/, "", msg)
		irc_say(msg)
		return
	}

	irc_say(HELP[topic])
}

BEGIN {
	HELP["help"] = CMD_PREFIX"help [TOPIC]: list help topics or help for a specific topic"
}

irc_cmd == "help" {
	help(util_array_slice(irc_msgv, 2, irc_msgv_len))
	next
}
