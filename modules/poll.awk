# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

function poll_vote(        poll, choice, account, msg, bangpath, path) {
	poll = irc_msgv[2]

	if (!((irc_channel, poll) in POLLS)) {
		irc_say(irc_channel, "Poll does not exist")
		return
	}
	if (irc_msgv_len < 3) {
		irc_say(irc_channel, "Please enter a choice")
		return
	}
	if ("account-tag" in IRC_CAPS) {
		if (IRC_TAGS["account"])
			account = IRC_TAGS["account"]
		else {
			irc_say(irc_channel, irc_nick": Only registered users may vote.")
			return
		}
	} else {
		log_warning("Voting is per-nick...")
		account = irc_nick
	}

	choice = util_array_slice(irc_msgv, 3, irc_msgv_len)
	if (((irc_channel, poll) in POLL_CHOICES) && !((irc_channel, poll, choice) in POLL_CHOICES)) {
		for (bangpath in POLL_CHOICES) {
			split(bangpath, path, SUBSEP)
			if (path[1] != irc_channel || path[2] != poll || !path[3])
				continue
			msg = msg ", '"path[3]"'"
		}
		sub(/^, /, "", msg)
		msg = "Please enter a valid choice: "msg
		irc_say(irc_channel, msg)
		return
	}

	# Already voted? Change your vote
	if ((irc_channel, poll, account) in POLLS)
		POLL_CHOICES[irc_channel, poll, POLLS[irc_channel, poll, account]] -= 1
	else
		POLLS[irc_channel, poll] += 1
	POLLS[irc_channel, poll, account] = choice
	POLL_CHOICES[irc_channel, poll, choice] += 1
	irc_say(irc_channel, irc_nick": Your vote has been counted, thank you.")
}

function poll_start(        bangpath, path, i) {
	if (irc_channel !~ /^[#&]/) {
		irc_say(irc_channel, "Polls can only be started in channels.")
		return
	}
	if ((irc_channel, irc_msgv[3]) in POLLS) {
		# Poll already in progress
		poll_end(irc_msgv[3], 0)
		return
	}

	irc_say(irc_channel, "Starting poll: "irc_msgv[3])
	if (irc_msgv_len > 3) {
		bangpath = util_array_slice(irc_msgv, 4, irc_msgv_len)
		split(bangpath, path, /[ ]*,[ ]*/)
		POLL_CHOICES[irc_channel, irc_msgv[3]] = 0
		for (i in path)
			POLL_CHOICES[irc_channel, irc_msgv[3], path[i]] = 0
	}
	POLLS[irc_channel, irc_msgv[3]] = 0
	POLL_OWNERS[irc_channel, irc_msgv[3]] = irc_nick
}

function poll_list(all,        bangpath, path, msg) {
	msg = ""
	for (bangpath in POLLS) {
		split(bangpath, path, SUBSEP)
		if (!all && path[1] != irc_channel)
			continue
		if (!path[2] || path[3])
			continue
		msg = msg ", "
		if (all)
			msg = msg path[1] "/"
		msg = msg path[2] " ("POLLS[bangpath]" votes)"
	}
	sub(/^, /, "", msg)
	if (msg)
		irc_say(irc_channel, "Active polls: "msg)
	else
		irc_say(irc_channel, "No active polls")
}

function poll_end(poll, end,       bangpath, path, msg, file, url) {
	if (end && !irc_admin && POLL_OWNERS[irc_channel, poll] != irc_nick) {
		irc_say(irc_channel, "This poll is owned by "POLL_OWNERS[irc_channel, poll])
		return
	}

	if (end)
		msg = "Poll ended. "
	msg = msg"Total votes: "POLLS[irc_channel, poll]

	if (end) {
		if (end >= 2)
			file = POLL_DIR "/poll."systime()

		delete POLLS[irc_channel, poll]
		for (bangpath in POLLS) {
			split(bangpath, path, SUBSEP)
			if (path[1] != irc_channel || path[2] != poll || !path[3])
				continue

			if (end >= 2)
				printf "%s\t%s\n", path[3], POLLS[bangpath] > file

			delete POLLS[bangpath]
		}

		if (end >= 2)
			close(file)
		if (end == 3) {
			file = "curl -F 'tpaste=<-' https://tpaste.us/ < "util_shell_quote(file)
			file | getline url
		}
	}

	for (bangpath in POLL_CHOICES) {
		split(bangpath, path, SUBSEP)
		if (path[1] != irc_channel || path[2] != poll || !path[3])
			continue
		if (POLL_CHOICES[bangpath] > 0)
			msg = msg"; '"path[3]"': "POLL_CHOICES[bangpath]" votes"

		if (end)
			delete POLL_CHOICES[bangpath]
	}
	irc_say(irc_channel, msg)
	if (url)
		irc_say(irc_channel, url)

	if (end) {
		delete POLL_CHOICES[irc_channel, poll]
		delete POLL_OWNERS[irc_channel, poll]
	}
}

irc_admin && irc_msgv[1] == CMD_PREFIX"poll" {
	if (irc_msgv[2] == "listall") {
		poll_list(1)
		next
	} else if (irc_msgv[2] == "export") {
		poll_end(irc_msgv[3], 2)
		next
	} else if (irc_msgv[2] == "publish") {
		poll_end(irc_msgv[3], 3)
		next
	}
}

irc_msgv[1] == CMD_PREFIX"poll" {
	if (!irc_msgv[2] || irc_msgv[2] == "list") {
		poll_list(0)
		next
	} else if (irc_msgv[2] == "start") {
		poll_start()
		next
	} else if (irc_msgv[2] == "status") {
		poll_end(irc_msgv[3], 0)
		next
	} else if (irc_msgv[2] == "end") {
		poll_end(irc_msgv[3], 1)
		next
	}
}

irc_msgv[1] == CMD_PREFIX"vote" {
	poll_vote()
	next
}
