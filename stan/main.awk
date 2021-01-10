# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

BEGIN {
	# Since \n can't appear in IRC messages except to delimit
	# end-of-message, this is a safer choice - many array indices
	# are from untrusted IRC input...
	SUBSEP = "\n"
	config_load()
	srand()
	RS = "\n"
	FS = " "

	if (!CHILD) {
		child_number = 1
		child_status = system("./stan.sh -v CHILD="child_number)
		while (child_status == 69) {
			child_number++
			child_status = system("./stan.sh -v CHILD="child_number)
		}
		exit child_status
	}

	log_warning("****** STARTING CHILD #" CHILD " ******")

	if (CHILD == 1) {
		irc_cmd("CAP", "REQ :account-tag batch chghost message-tags")
		irc_cmd("CAP", "END")
		if (IRC_PASSWORD) {
			log_info("*** PASS *******")
			print "PASS "IRC_PASSWORD
			fflush()
		}
	}
	irc_set_nick(IRC_NICK)
	if (CHILD == 1)
		irc_cmd("USER", IRC_USERNAME " * * :" IRC_GECOS)
	else
		irc_sync()
}
