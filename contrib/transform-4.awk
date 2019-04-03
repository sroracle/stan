# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019 Max Rees
# See LICENSE for more information.

# Transform a markov-2x1 database into a markov-2x1 compact database

function new_entry() {
	KEY = $1
	printf "\n%s ", KEY
}

BEGIN {
	new_entry()
}

{
	if (NF < 2)
		next

	if ($1 != KEY)
		new_entry()
	else
		printf "\035"

	printf "%s", $2
	if (NF == 3)
		printf " %s", $3
}
