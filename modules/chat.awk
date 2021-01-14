# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

function chat_markov(trigger, channel, msg) {
	log_debug("--- markov: ("trigger"/"channel") "msg)
	printf "%d %s %s\n", trigger, channel, msg | CHAT_CMD
	fflush(CHAT_CMD)
}

function chat(channel, msg) {
	if (channel in CHAT_CHANNELS && (msg ~ CHAT_PATTERN || util_randrange(0, 300) == 67)) {
		sub(ADDRESS_PATTERN, "", msg)
		chat_markov(2, channel, msg)
	}

	else if (channel in CHAT_LEARN_CHANNELS && !index(msg, "http") && util_randrange(0, 10) == 7)
		chat_markov(1, channel, msg)

	else
		chat_markov(0, channel, msg)

}

BEGIN {
	CHAT_CMD = "python3 modules/markov.py "util_shell_quote(CHAT_FILE)
}

irc_admin && irc_msgv[1] == CMD_PREFIX"chat" {
	CHAT_CHANNELS[irc_channel] = 1
	next
}

irc_admin && irc_msgv[1] == CMD_PREFIX"quiet" {
	delete CHAT_CHANNELS[irc_channel]
	next
}

irc_msg {
	chat(irc_channel, irc_msg)
}

END {
	close(CHAT_CMD)
}
