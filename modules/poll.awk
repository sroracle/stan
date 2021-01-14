# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

function poll_vote(channel, nick, cmd, cmdlen,        poll, choice, account, msg, bangpath, path) {
	poll = cmd[2]

	if (!((channel, poll) in POLLS)) {
		irc_say(channel, "Poll does not exist")
		return
	}
	if (cmdlen < 3) {
		irc_say(channel, "Please enter a choice")
		return
	}
	if ("account-tag" in IRC_CAPS) {
		if (IRC_TAGS["account"])
			account = IRC_TAGS["account"]
		else {
			irc_say(channel, nick ": Only registered users may vote.")
			return
		}
	} else {
		log_warning("Voting is per-nick...")
		account = nick
	}

	choice = util_array_slice(cmd, 3, cmdlen)
	if (((channel, poll) in POLL_CHOICES) && !((channel, poll, choice) in POLL_CHOICES)) {
		for (bangpath in POLL_CHOICES) {
			split(bangpath, path, SUBSEP)
			if (path[1] != channel || path[2] != poll || !path[3])
				continue
			msg = msg ", '" path[3] "'"
		}
		sub(/^, /, "", msg)
		msg = "Please enter a valid choice: " msg
		irc_say(channel, msg)
		return
	}

	# Already voted? Change your vote
	if ((channel, poll, account) in POLLS)
		POLL_CHOICES[channel, poll, POLLS[channel, poll, account]] -= 1
	else
		POLLS[channel, poll] += 1
	POLLS[channel, poll, account] = choice
	POLL_CHOICES[channel, poll, choice] += 1
	irc_say(channel, nick ": Your vote has been counted, thank you.")
}

function poll_start(channel, nick, cmd, cmdlen,        bangpath, path, i) {
	if (channel !~ /^[#&]/) {
		irc_say(channel, "Polls can only be started in channels.")
		return
	}
	if ((channel, cmd[3]) in POLLS) {
		# Poll already in progress
		poll_end(channel, "", cmd[3], 0)
		return
	}

	irc_say(channel, "Starting poll: " cmd[3])
	if (cmdlen > 3) {
		bangpath = util_array_slice(cmd, 4, cmdlen)
		split(bangpath, path, /[ ]*,[ ]*/)
		POLL_CHOICES[channel, cmd[3]] = 0
		for (i in path)
			POLL_CHOICES[channel, cmd[3], path[i]] = 0
	}
	POLLS[channel, cmd[3]] = 0
	POLL_OWNERS[channel, cmd[3]] = nick
}

function poll_list(channel, all,        bangpath, path, msg) {
	msg = ""
	for (bangpath in POLLS) {
		split(bangpath, path, SUBSEP)
		if (!all && path[1] != channel)
			continue
		if (!path[2] || path[3])
			continue
		msg = msg ", "
		if (all)
			msg = msg path[1] "/"
		msg = msg path[2] " (" POLLS[bangpath] " votes)"
	}
	sub(/^, /, "", msg)
	if (msg)
		irc_say(channel, "Active polls: " msg)
	else
		irc_say(channel, "No active polls")
}

function poll_end(channel, nick, poll, end,       bangpath, path, msg, file, url) {
	if (nick && POLL_OWNERS[channel, poll] != nick) {
		irc_say(channel, "This poll is owned by " POLL_OWNERS[channel, poll])
		return
	}

	if (end)
		msg = "Poll ended. "
	msg = msg "Total votes: " POLLS[channel, poll]

	if (end) {
		if (end >= 2)
			file = POLL_DIR "/poll." systime()

		delete POLLS[channel, poll]
		for (bangpath in POLLS) {
			split(bangpath, path, SUBSEP)
			if (path[1] != channel || path[2] != poll || !path[3])
				continue

			if (end >= 2)
				printf "%s\t%s\n", path[3], POLLS[bangpath] > file

			delete POLLS[bangpath]
		}

		if (end >= 2)
			close(file)
		if (end == 3) {
			file = "curl -F 'tpaste=<-' https://tpaste.us/ < " util_shell_quote(file)
			file | getline url
		}
	}

	for (bangpath in POLL_CHOICES) {
		split(bangpath, path, SUBSEP)
		if (path[1] != channel || path[2] != poll || !path[3])
			continue
		if (POLL_CHOICES[bangpath] > 0)
			msg = msg "; '" path[3] "': " POLL_CHOICES[bangpath] " votes"

		if (end)
			delete POLL_CHOICES[bangpath]
	}
	irc_say(channel, msg)
	if (url)
		irc_say(channel, url)

	if (end) {
		delete POLL_CHOICES[channel, poll]
		delete POLL_OWNERS[channel, poll]
	}
}

irc_admin && irc_msgv[1] == CMD_PREFIX"poll" {
	if (irc_msgv[2] == "coup") {
		poll_end(irc_channel, "", irc_msgv[3], 1)
		next
	} else if (irc_msgv[2] == "listall") {
		poll_list(irc_channel, 1)
		next
	} else if (irc_msgv[2] == "export") {
		poll_end(irc_channel, "", irc_msgv[3], 2)
		next
	} else if (irc_msgv[2] == "publish") {
		poll_end(irc_channel, "", irc_msgv[3], 3)
		next
	}
}

irc_msgv[1] == CMD_PREFIX"poll" {
	if (!irc_msgv[2] || irc_msgv[2] == "list") {
		poll_list(irc_channel, "")
		next
	} else if (irc_msgv[2] == "start") {
		poll_start(irc_channel, irc_nick, irc_msgv, irc_msgv_len)
		next
	} else if (irc_msgv[2] == "status") {
		poll_end(irc_channel, "", irc_msgv[3], 0)
		next
	} else if (irc_msgv[2] == "end") {
		poll_end(irc_channel, "", irc_msgv[3], 1)
		next
	}
}

irc_msgv[1] == CMD_PREFIX"vote" {
	poll_vote(irc_channel, irc_nick, irc_msgv, irc_msgv_len)
	next
}
