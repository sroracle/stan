# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_admin && irc_cmd == "identify" {
	irc_identify()
	next
}

irc_admin && irc_cmd == "join" {
	for (_admin_i = 2; _admin_i <= irc_msgv_len; _admin_i++) {
		IRC_CHANNELS[irc_msgv[_admin_i]] = 0
		irc_do("JOIN "irc_msgv[_admin_i])
	}
	next
}

irc_admin && irc_cmd == "nick" {
	irc_set_nick(irc_msgv[2])
	next
}

irc_admin && irc_cmd == "part" {
	for (_admin_i = 2; _admin_i <= irc_msgv_len; _admin_i++) {
		util_rm_subarray(IRC_NAMES, irc_msgv[_admin_i])
		delete IRC_CHANNELS[irc_msgv[_admin_i]]
		irc_do("PART "irc_msgv[_admin_i]" :See ya later")
	}
	next
}

irc_admin && irc_cmd == "quit" {
	irc_do("QUIT :See ya later")
	next
}

irc_admin && irc_cmd == "restart" {
	if (system(CONSTANTS_START_SCRIPT" -W dump >/dev/null")) {
		irc_say("Compilation failed; refusing to restart.")
		next
	}
	irc_say("Killing child #" CHILD)
	log_warning("****** STOPPING CHILD #" CHILD " ******")
	exit EXIT_RESTART
}

irc_admin && irc_cmd == "sync" {
	irc_sync()
	next
}

irc_admin && irc_cmd == "tell" {
	irc_tell(irc_msgv[2], util_array_slice(irc_msgv, 3, irc_msgv_len))
	next
}
