# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

function quotes_grab(qchan, nick, quote) {
	if (nick && !((qchan, nick) in QUOTES)) {
		irc_say(irc_channel, "who?")
		return
	} else if (nick)
		quote = QUOTES[qchan, nick]
	else if (qchan && (qchan in QUOTES))
		quote = QUOTES[qchan]
	else if (quote)
		quote = quote
	else {
		irc_say(irc_channel, "huh?")
		return
	}

	print quote >> (QUOTE_FILE)
	close(QUOTE_FILE)
	irc_say(irc_channel, "Quote added")
}

function quotes_rand(search,        argv, quote) {
	if (search) {
		argv = "grep -Fi " util_shell_quote(search) " " util_shell_quote(QUOTE_FILE)
		argv = argv " | shuf -n1 "
	} else
		argv = "shuf -n1 " util_shell_quote(QUOTE_FILE)

	quote = util_get_output(argv)
	if (!quote)
		irc_say(irc_channel, "No results")
	else
		irc_say(irc_channel, quote)
}

irc_channel ~ /^[#&]/ && irc_msgv[1] == CMD_PREFIX"add" && !irc_ignore {
	quotes_grab("", "", util_array_slice(irc_msgv, 2, irc_msgv_len))
	next
}

irc_channel ~ /^[#&]/ && irc_msgv[1] == CMD_PREFIX"grab" && !irc_ignore {
	if (irc_msgv[2])
		quotes_grab(irc_channel, irc_msgv[2])
	else
		quotes_grab(irc_channel)
	next
}

irc_msgv[1] == CMD_PREFIX"rand" && !irc_ignore {
	if (irc_msgv[2])
		quotes_rand(util_array_slice(irc_msgv, 2, irc_msgv_len))
	else
		quotes_rand()
	next
}

irc_channel ~ /^[#&]/ && irc_msgv[1] !~ "^"CMD_PREFIX {
	QUOTES[irc_channel] = "<"irc_nick"> "irc_msg
	QUOTES[irc_channel, irc_nick] = "<"irc_nick"> "irc_msg
}
