# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_admin && irc_msgv[1] == CMD_PREFIX"identify" {
	irc_identify()
	next
}

irc_admin && irc_msgv[1] == CMD_PREFIX"join" {
	for (_admin_i = 2; _admin_i <= irc_msgv_len; _admin_i++) {
		IRC_CHANNELS[irc_msgv[_admin_i]] = 0
		irc_cmd("JOIN", irc_msgv[_admin_i])
	}
	next
}

irc_admin && irc_msgv[1] == CMD_PREFIX"nick" {
	irc_set_nick(irc_msgv[2])
	next
}

irc_admin && irc_msgv[1] == CMD_PREFIX"part" {
	for (_admin_i = 2; _admin_i <= irc_msgv_len; _admin_i++) {
		util_rm_subarray(IRC_NAMES, irc_msgv[_admin_i])
		irc_cmd("PART", irc_msgv[_admin_i]" :See ya later")
	}
	next
}

irc_admin && irc_msgv[1] == CMD_PREFIX"quit" {
	irc_cmd("QUIT", ":See ya later")
	next
}

irc_admin && irc_msgv[1] == CMD_PREFIX"restart" {
	if (system("./stan.sh -W dump >/dev/null")) {
		irc_say(irc_channel, "Compilation failed; refusing to restart.")
		next
	}
	irc_say(irc_channel, "Killing child #" CHILD)
	log_warning("****** STOPPING CHILD #" CHILD " ******")
	exit 69
}

irc_admin && irc_msgv[1] == CMD_PREFIX"say" {
	irc_say(irc_msgv[2], util_array_slice(irc_msgv, 3, irc_msgv_len))
	next
}

irc_admin && irc_msgv[1] == CMD_PREFIX"sync" {
	irc_sync()
	next
}
