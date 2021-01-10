# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

$2 ~ /^(JOIN|QUIT)$/ && irc_nick == "joe" {
	if (irc_channel == "#sporks" && $2 == "JOIN")
		irc_say("#sporks", "boj")
	else if ($2 == "QUIT" && ("#sporks", "joe") in IRC_NAMES)
		irc_say("#sporks", "eoj")
}
