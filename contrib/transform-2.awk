# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019 Max Rees
# See LICENSE for more information.

# Transform a markov-1x1 database into a complete line database
BEGIN {
	FS = " "
	first = 1
}

{
	if (first) {
		printf "%s %s", $1, $2
		first = 0
		word2 = $2
		next
	}

	if (word2 == $1) {
		printf " %s", $2
	} else {
		printf "\n%s %s", $1, $2
	}
	word2 = $2
}
