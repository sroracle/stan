# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019 Max Rees
# See LICENSE for more information.

# Return a random integer in the closed interval [lower, upper]
# since rand() returns a floating point number in the half-open
# interval [0, 1)
function randrange(lower, upper) {
	return int((upper - lower + 1) * rand()) + lower
}

function choose(        i, words, adding_len, last_len) {
	if (num_choices == 0) {
		sentence[++cur_len] = other_choice
		seed = other_choice

	} else {
		num_choices = randrange(1, num_choices)
		i = randrange(1, choices[num_choices])
		adding_len = split(choices[num_choices, i], words, " ")
		for (i = 1; i <= adding_len; i++)
			sentence[++cur_len] = words[i]
		seed = words[adding_len]
	}

	if (cur_len >= want_len)
		exit

	last_len = length(sentence[cur_len])
	if (index(sentence[cur_len], "\036") == last_len) {
		sentence[cur_len] = substr(sentence[cur_len], 1, last_len - 1)
		exit
	}
}

function reset() {
	num_other = randrange(1, dendrites)
	num_choices = 0
}

BEGIN {
	srand()
	FS = " "
	OFS = " "

	cur_len = 0
	want_len = randrange(1, 10)
	if (want_len == 1)
		want_len = randrange(1, 10)
	else if (want_len == 10)
		want_len = randrange(21, 26)
	else
		want_len = randrange(10, 21)
}

{
	if (FNR == 1) {
		if (NR != 1)
			choose()
		reset()
	}

	if (FNR == num_other)
		other_choice = $1

	if (FNR == dendrites) {
		ARGC++
		ARGV[ARGC - 1] = FILENAME
		nextfile
	}
}

$1 == seed {
	choices[++num_choices] = split(substr($0, length($1) + 2), new_choices, "\035")
	for (i = 1; i <= choices[num_choices]; i++)
		choices[num_choices, i] = new_choices[i]
	delete new_choices
}

$1 > seed {
	if (num_choices != 0 || (num_choices == 0 && FNR > num_other)) {
		ARGC++
		ARGV[ARGC - 1] = FILENAME
		nextfile
	}
}

END {
	if (cur_len > 0)
		printf "%s", sentence[1]
	for (i = 2; i <= cur_len; i++)
		printf " %s", sentence[i]
	printf "\n"
}
