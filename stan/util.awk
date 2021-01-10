# SPDX-License-Identifier: EFL-2.0 AND GPL-3.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.
#
# The util_shell_quote function was adapted from:
# https://www.gnu.org/software/gawk/manual/html_node/Shell-Quoting.html
# Copyright (c) 2014 Michael Brennan
# See LICENSE.GPL3 for more information.

function util_age(        delta, days, hours, mins, secs) {
	delta = systime() - UTIL_BIRTH
	days = int(delta / (3600 * 24))
	if (days > 0) {
		if (days == 1)
			days = days " day, "
		else
			days = days " days, "
		hours = int((delta % (3600 * 24)) / 3600)
	} else {
		days = ""
		hours = int(delta / 3600)
	}
	mins = int((delta % 3600) / 60)
	secs = delta % 60
	return sprintf("%s%02d:%02d:%02d", days, hours, mins, secs)
}

function util_array_slice(array, lower, upper,        i) {
		s = ""
		for (i = lower; i <= upper; i++)
			s = s " " array[i]
		sub(/^ /, "", s)
		return s
}

function util_get_output(argv,        output) {
	(argv) | getline output
	close(argv)
	return output
}

# Return a random integer in the closed interval [lower, upper]
# since rand() returns a floating point number in the half-open
# interval [0, 1)
function util_randrange(lower, upper) {
	return int((upper - lower + 1) * rand()) + lower
}

function util_rm_field(field,        i) {
	for (i = field; i <= NF; i++)
		$(i) = $(i+1)
	NF -= 1
}

function util_rm_subarray(array, key1,        bangpath, path) {
	for (bangpath in array) {
		split(bangpath, path, SUBSEP)
		if (path[1] != key1)
			continue
		delete array[bangpath]
	}
	delete array[key1]
}

function util_shell_quote(str,        SINGLE, QSINGLE, len, exploded, i) {
	if (str == "")
		return "\047\047"

	SINGLE = "\047"
	QSINGLE = "\"\047\""
	len = split(str, exploded, SINGLE)

	str = SINGLE exploded[1] SINGLE
	for (i = 2; i <= len; i++)
		str = str QSINGLE SINGLE exploded[i] SINGLE

	return str
}

BEGIN {
	UTIL_BIRTH = systime()
}
