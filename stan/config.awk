# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

function config_load() {
	FS = "="

	while ((getline < ENVIRON["STAN_CFG"]) == 1) {
		if ($1 == "BRAIN_FILE")
			CHAT_FILE = $2
		else if ($1 == "QUOTE_FILE")
			QUOTE_FILE = $2
		else if ($1 == "POLL_DIR")
			POLL_DIR = $2
		else if ($1 == "OWNERMASK")
			OWNERMASK = $2
		else if ($1 == "NICK")
			IRC_NICK = $2
		else if ($1 == "USERNAME")
			IRC_USERNAME = $2
		else if ($1 == "PASSWORD")
			IRC_PASSWORD = $2
		else if ($1 == "GECOS")
			IRC_GECOS = $2
		else if ($1 == "CMD_PATTERN")
			CMD_PATTERN = $2
		else if ($1 == "CHANNELS")
			IRC_CHANNELS[$2] = 0
		else if ($1 == "BATTLE_CHANS")
			BATTLE_CHANNELS[$2] = 1
		else if ($1 == "CHAT_CHANS")
			CHAT_CHANNELS[$2] = 1
		else if ($1 == "LEARN_CHANS")
			CHAT_LEARN_CHANNELS[$2] = 1
		else if ($1 == "UNO_MASTER")
			UNO_MASTER = $2
		else if ($1 == "IGNORE")
			IGNORE[$2] = 1
		else if ($1 == "IGNOREPAT")
			IGNORE_PATTERN[$2] = 1
		else if ($1 == "VERBOSE")
			VERBOSE = $2
		else if (index($1, "#") != 1)
			log_warning("Unknown configuration option: '" $1 "'")
	}

	close(ENVIRON["STAN_CFG"])
	FS = " "
}
