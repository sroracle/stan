# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019 Max Rees
# See LICENSE for more information.

# Transform a complete line database into a markov-2x1 database
{
	if (NF < 2) {
		next
	}

	if (NF < 3) {
		printf "%s %s\036\n", $1, $2
		next
	}

	for (i = 1; i <= NF - 2; i++) {
		if (i + 1 > NF - 2) {
			end = "\036\n"
		} else {
		  end = "\n"
		}
		printf "%s %s %s%s", $(i), $(i + 1), $(i + 2), end
	}
}
