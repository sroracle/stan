# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

function log_info(msg) {
	print msg > "/dev/stderr"
	fflush("/dev/stderr")
}

function log_debug(msg) {
	if (!VERBOSE)
		return
	log_info(msg)
}

# Only print once. Useful for ensuring some output from server is seen when
# !VERBOSE, but not printed when VERBOSE
function log_ndebug(msg) {
	if (VERBOSE)
		return
	log_info(msg)
}

function log_warning(msg) {
	log_info("*** " msg)
}
