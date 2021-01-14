# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

irc_msgv_len == 1 && irc_msgv[1] == "h" {
	irc_say("h")
	next
}
