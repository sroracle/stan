# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2021 Max Rees
# See LICENSE for more information.

BEGIN {
	# https://tools.ietf.org/html/draft-hardy-irc-isupport-00#section-4.1
	CONSTANTS_CASEFOLD_UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^"
	CONSTANTS_CASEFOLD_LOWER = "abcdefghijklmnopqrstuvwxyz{|}~"
	CONSTANTS_CASEFOLD_MAX["ascii"] = 26
	CONSTANTS_CASEFOLD_MAX["strict-rfc1459"] = 29
	CONSTANTS_CASEFOLD_MAX["rfc1459"] = 30
	# Set a default casemapping - this can be changed if the server
	# sends ISUPPORT CASEMAPPING=
	IRC_CASEMAPPING = "strict-rfc1459"
}
