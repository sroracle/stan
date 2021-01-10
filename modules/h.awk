# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_msg ~ /^[ ]*h[ ]*$/ {
	irc_say(irc_channel, "h")
	next
}
