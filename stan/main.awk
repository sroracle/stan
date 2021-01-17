# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

BEGIN {
	RS = "\n"
	FS = " "
	# Since \n can't appear in IRC messages except to delimit
	# end-of-message, this is a safer choice - many array indices
	# are from untrusted IRC input...
	SUBSEP = "\n"

	config_load()
	srand()

	EXIT_RESTART = 69
	if (!CHILD) {
		child_number = 1
		child_status = system(CONSTANTS_START_SCRIPT" -v CHILD="child_number)
		while (child_status == EXIT_RESTART) {
			child_number++
			child_status = system(CONSTANTS_START_SCRIPT" -v CHILD="child_number)
		}
		exit child_status
	}

	log_warning("****** STARTING CHILD #"CHILD" ******")

	if (CHILD == 1) {
		irc_do("CAP REQ :"CONSTANTS_WANT_CAPS)
		irc_do("CAP END")
		if (IRC_PASSWORD) {
			log_info("*** PASS *******")
			print "PASS "IRC_PASSWORD
			fflush()
		}
	}
	irc_set_nick(IRC_NICK)
	if (CHILD == 1)
		irc_do("USER "IRC_USERNAME" * * :"IRC_GECOS)
	else
		irc_sync()
}
