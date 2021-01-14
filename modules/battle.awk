# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

function battle(        bangpath, path, members) {
	for (bangpath in IRC_NAMES) {
		split(bangpath, path, SUBSEP)
		if (path[1] != irc_channel || !path[2])
			continue
		members = members","path[2]
	}
	sub(/^,/, "", members)
	log_debug("--- battle: ("irc_channel"/"members"/"irc_nick") "irc_msg)
	printf "%s %s %s %s\n", irc_channel, members, irc_nick, irc_msg | BATTLE_CMD
	fflush(BATTLE_CMD)
}

BEGIN {
	BATTLE_CMD = "php modules/battlebot.php"
}

irc_channel in BATTLE_CHANNELS && irc_msg ~ "^\001ACTION (attacks|stabs|fites|throws|drops|thwacks|casts|heals) " {
	battle()
	next
}

END {
	close(BATTLE_CMD)
}
