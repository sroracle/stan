# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

function quotes_grab(qchan, nick, quote) {
	if (nick && !((qchan, nick) in QUOTES)) {
		irc_say("who?")
		return
	} else if (nick)
		quote = QUOTES[qchan, nick]
	else if (qchan && (qchan in QUOTES))
		quote = QUOTES[qchan]
	else if (quote)
		quote = quote
	else {
		irc_say("huh?")
		return
	}

	print quote >> (QUOTE_FILE)
	close(QUOTE_FILE)
	irc_say("Quote added")
}

function quotes_rand(search,        argv, quote) {
	if (search) {
		argv = "grep -Fi "util_shell_quote(search)" "util_shell_quote(QUOTE_FILE)
		argv = argv" | shuf -n1"
	} else
		argv = "shuf -n1 "util_shell_quote(QUOTE_FILE)

	quote = util_get_output(argv)
	if (!quote)
		irc_say("No results")
	else
		irc_say(quote)
}

BEGIN {
	HELP["add"] = CMD_PREFIX"add [QUOTE_TEXT]: add a quote to the quote database"
	HELP["grab"] = CMD_PREFIX"grab [NICK]: add the last line from the NICK or the channel to the quote database"
	HELP["rand"] = CMD_PREFIX"rand [SEARCH_TERMS]: get a random quote or search for one"
}

irc_msg_public && irc_cmd == "add" && !irc_ignore {
	quotes_grab("", "", util_array_slice(irc_msgv, 2, irc_msgv_len))
	next
}

irc_msg_public && irc_cmd == "grab" && !irc_ignore {
	quotes_grab(irc_channel, irc_msgv[2])
	next
}

irc_cmd == "rand" && !irc_ignore {
	quotes_rand(util_array_slice(irc_msgv, 2, irc_msgv_len))
	next
}

irc_msg_public && !irc_cmd {
	QUOTES[irc_channel] = "<"irc_nick"> "irc_msg
	QUOTES[irc_channel, irc_nick] = "<"irc_nick"> "irc_msg
}
