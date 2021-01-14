# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

function irc_send(msg) {
	log_debug(">>> "msg)
	print msg
	fflush()
}

function irc_do(cmd) {
	log_ndebug(">>> "cmd)
	irc_send(cmd)
}

function irc_case_expand(c) {
	if (c == "[" || c == "{")
		return "[[{]"
	else if (c == "]" || c == "}")
		return "[]}]"
	else if (c == "|" || c == "\\")
		return "[|\\\\]"
	else if (c == "^")
		return "\\^"
	else if (c == "`" || c == "-")
		return c
	else
		return "["tolower(c) toupper(c)"]"
}

function irc_identify() {
	if (!IRC_PASSWORD)
		return
	log_info(">>> PRIVMSG NickServ :identify "IRC_NICK" *******")
	print "PRIVMSG NickServ :identify "IRC_NICK" "IRC_PASSWORD
	fflush()
}

function irc_rand_nick(channel,        i, j, bangpath, path) {
	j = util_randrange(1, IRC_CHANNELS[channel])
	i = 0
	for (bangpath in IRC_NAMES) {
		i++
		split(bangpath, path, SUBSEP)
		if (path[1] == channel && i == j)
			return path[2]
	}
}

function irc_save_isupport(        token, sep, value, i, j) {
	for (i = 4; i <= NF; i++) {
		token = $(i)
		if (!token)
			continue
		sep = index(token, "=")
		if (sep) {
			value = substr(token, sep + 1)
			token = substr(token, 1, sep - 1)
		}
		if (token ~ "^-") {
			sub(/^-/, "", token)
			delete IRC_ISUPPORT[token]
			continue
		}

		IRC_ISUPPORT[token] = value
		log_debug("ISUPPORT "token"="value"")

		if (token == "BOT")
			irc_do("MODE "IRC_NICK" +"value)
		else if (token == "CHANTYPES") {
			delete IRC_CHANTYPES
			for (j = 1; j <= length(value); j++) {
				sep = substr(value, j, 1)
				IRC_CHANTYPES[sep] = 1
				log_warning("CHANTYPE="sep)
			}
		} else if (token == "PREFIX") {
			delete IRC_PREFIX
			sub(/^[(][^)]+[)]/, "", value)
			for (j = 1; j <= length(value); j++) {
				sep = substr(value, j, 1)
				IRC_PREFIX[sep] = 1
				log_warning("PREFIX="sep)
			}
		}
	}
}

function irc_save_tags(        tags, tag, sep, value) {
	delete IRC_TAGS
	if (!("message-tags" in IRC_CAPS && $1 ~ "^@"))
		return

	$1 = substr($1, 2)
	split($1, tags, ";")
	for (tag in tags) {
		tag = tags[tag]
		sep = index(tag, "=")
		if (sep) {
			value = substr(tag, sep + 1)
			tag = substr(tag, 1, sep - 1)
		}
		IRC_TAGS[tag] = value
	}
	delete tags
	util_rm_field(1)
}

function irc_tell(channel, msg) {
	if (length(msg) > 450) {
		IRC_MORE[channel] = substr(msg, 451, length(msg))
		msg = substr(msg, 1, 450)" [%more]"
	}

	log_ndebug(sprintf(">>> (%s) <%s> %s", channel, IRC_NICK, msg))
	irc_send("PRIVMSG "channel" :" msg)
}

function irc_say(msg) {
	irc_tell(irc_channel, msg)
}

function irc_set_nick(nick) {
	IRC_NICK = nick
	irc_do("NICK "nick)

	nick_pattern = ""
	for (i = 1; i <= length(IRC_NICK); i++) {
		c = substr(IRC_NICK, i, 1)
		c = irc_case_expand(c)
		nick_pattern = nick_pattern c
	}

	log_info("Nick pattern is: "nick_pattern)

	ADDRESS_PATTERN = "^"nick_pattern"[:, ]+ ?"
	CHAT_PATTERN = "[^]^a-z0-9{}_`|\\\\])"
	CHAT_PATTERN = "(^|"CHAT_PATTERN nick_pattern"($|" CHAT_PATTERN
}

function irc_strip_prefix(s,        i) {
	for (i = 1; i <= length(s); i++)
		if (!(substr(s, i, 1) in IRC_PREFIX)) {
			break
		}
	return substr(s, i)
}

function irc_sync() {
	delete IRC_CAPS
	delete IRC_ISUPPORT
	delete IRC_CHANNELS
	delete IRC_NAMES

	delete IRC_CHANTYPES
	delete IRC_PREFIX

	irc_identify()
	irc_do("CAP LIST")
	irc_do("VERSION")
	irc_do("WHOIS "IRC_NICK)
}

{
	irc_admin = 0
	irc_ignore = 0
	irc_msg_public = 0
	irc_nick = ""
	irc_hostmask = ""
	irc_channel = ""
	irc_msg = ""
	delete irc_msgv
	irc_msgv_len = 0
	irc_cmd = ""

	log_debug("<<< "$0)
	sub(/[\r\n]+$/, "")
	irc_save_tags()
}

# Welcome message - usually safe to join now
$2 == "001" {
	log_warning("Connected!")
	for (_irc_channel in IRC_CHANNELS)
		irc_do("JOIN "_irc_channel)
	next
}

# ISUPPORT
#                      $4
# :server 005 NICK TOKEN=VALUE TOKEN2 -TOKEN3 ... :are supported by this server
# PREFIX=(qaohv)~&@%+
$2 == "005" {
	if ($0 !~ /:are supported by this server$/)
		next
	sub(/:are supported by this server$/, "")
	irc_save_isupport()
	next
}

# WHOIS
#    $1   $2   $3   $4     $5      $6      $7
# :server 319 NICK nick :#chan1 +#chan2 @#chan3
$2 == "319" {
	if ($4 == IRC_NICK) {
		sub(/^:/, "", $5)
		for (_irc_i = 5; _irc_i <= NF; _irc_i++) {
			_irc_channel = $(_irc_i)
			_irc_channel = irc_strip_prefix(_irc_channel)
			IRC_CHANNELS[_irc_channel] = 0
			irc_do("NAMES "_irc_channel)
		}
	}
	next
}

# NAMES
#    $1   $2   $3    $4     $5      $6     $7     $8
# :server 353 NICK [@*=] #channel :nick1 +nick2 @nick3
$2 == "353" {
	_irc_channel = $5

	_irc_s = ""
	sub(/^:/, "", $6)
	for (_irc_i = 6; _irc_i <= NF; _irc_i++) {
		_irc_nick = $(_irc_i)
		_irc_nick = irc_strip_prefix(_irc_nick)
		_irc_s = _irc_s" "_irc_nick
		if (!((_irc_channel, _irc_nick) in IRC_NAMES)) {
			IRC_CHANNELS[_irc_channel] += 1
			IRC_NAMES[_irc_channel, _irc_nick] = 1
		}
	}

	log_warning("NAMES "_irc_channel" ("IRC_CHANNELS[_irc_channel]"):" _irc_s)
	next
}

# Display errors from the server (4xx, 5xx, and sometimes 9xx numerics)
$2 ~ /^[459][0-9][0-9]/ {
	log_ndebug("<<< "$0)
	next
}

$1 == "PING" {
	irc_send("PONG "$2)
	next
}

#                     $5
# :server CAP * ACK  :cap1 cap2
# :server CAP * LIST :cap1 cap2
$2 == "CAP" {
	sub(/^:/, "", $5)
	if ($4 == "ACK" || $4 == "LIST")
		for (_irc_i = 5; _irc_i <= NF; _irc_i++) {
			log_warning("CAP ACK "$(_irc_i))
			IRC_CAPS[$(_irc_i)] = 1
		}
	next
}

#            $2         $3           $4         $5
# :server BATCH +sxtUfAeXBgNoD chathistory :#channel
$2 == "BATCH" {
	sub(/^:/, "", $5)
	if ($3 ~ "^[+]" && $4 == "chathistory")
		IRC_IGNORE_BATCH[$5, substr($3, 2)] = 1
	else if ($3 ~ "^-")
		delete IRC_IGNORE_BATCH[$5, substr($3, 2)]
	next
}

# JOIN
#       $1         $2     $3
# :nick!user@host JOIN :#channel
# PART
#       $1         $2     $3
# :nick!user@host PART #channel :msg
# KICK
#       $1         $2     $3     $4
# :nick!user@host KICK #channel nick :msg
# QUIT
#       $1         $2
# :nick!user@host QUIT :msg
$2 ~ /^(JOIN|PART|KICK|QUIT)$/ {
	_irc_bang = index($1, "!")
	if (!_irc_bang)
		next
	irc_nick = substr($1, 2, _irc_bang - 2)
	if (irc_nick == IRC_NICK)
		next
	irc_channel = $3

	if ($2 == "JOIN")
		sub(/^:/, "", irc_channel)

	if ($2 == "JOIN") {
		IRC_CHANNELS[irc_channel] += 1
		IRC_NAMES[irc_channel, irc_nick] = 1
	}

	else if ($2 == "PART") {
		IRC_CHANNELS[irc_channel] -= 1
		delete IRC_NAMES[irc_channel, irc_nick]
	}

	else if ($2 == "KICK") {
		irc_nick = $4
		IRC_CHANNELS[irc_channel] -= 1
		delete IRC_NAMES[irc_channel, irc_nick]
	}

	else if ($2 == "QUIT") {
		for (_irc_bangpath in IRC_NAMES) {
			split(_irc_bangpath, path, SUBSEP)
			if (path[2] == irc_nick) {
				IRC_CHANNELS[irc_channel] -= 1
				delete IRC_NAMES[_irc_bangpath]
			}
		}
	}
}

#       $1          $2       $3     $4
# :nick!user@host PRIVMSG #channel :msg
$2 ~ "^(PRIVMSG|NOTICE)$" {
	_irc_bang = index($1, "!")
	if (!_irc_bang)
		next
	irc_nick = substr($1, 2, _irc_bang - 2)

	irc_hostmask = substr($1, _irc_bang + 1)
	irc_admin = irc_hostmask == OWNERMASK

	irc_channel = $3
	irc_msg_public = substr(irc_channel, 1, 1) in IRC_CHANTYPES

	sub(/^:/, "", $4)
	# FIXME this is hacky
	_irc_msgstart = length($1" "$2" "$3" ") + 1
	irc_msg = substr($0, _irc_msgstart)
	irc_msgv_len = split(irc_msg, irc_msgv, " ")
	if (substr(irc_msgv[1], 1, CMD_PREFIX_LEN) == CMD_PREFIX)
		irc_cmd = substr(irc_msgv[1], CMD_PREFIX_LEN+1)

	if (irc_channel == IRC_NICK) {
		irc_channel = irc_nick
		_irc_fmt = "("irc_nick")"
	} else
		_irc_fmt = "("irc_channel") <"irc_nick">"

	if ("batch" in IRC_TAGS && (irc_channel, IRC_TAGS["batch"]) in IRC_IGNORE_BATCH) {
		log_ndebug("~~~ "_irc_fmt" "irc_msg)
		next
	}

	log_debug("!!! NF = " NF)
	for (_irc_tag in IRC_TAGS)
		log_debug("!!! @" _irc_tag "=" IRC_TAGS[_irc_tag])

	for (_irc_pattern in IGNORE_PATTERN)
		if (irc_msg ~ _irc_pattern) {
			log_ndebug("~~~ "_irc_fmt" "irc_msg)
			irc_ignore = 1
			break
		}

	if (!irc_ignore) {
		if (irc_nick in IGNORE || irc_nick == IRC_NICK) {
			log_ndebug("~~~ "_irc_fmt" "irc_msg)
			irc_ignore = 1
		} else
			log_ndebug("<<< "_irc_fmt" "irc_msg)
	}
}

irc_cmd == "more" && !irc_ignore {
	if (IRC_MORE[irc_channel]) {
		_irc_more = IRC_MORE[irc_channel]
		delete IRC_MORE[irc_channel]
		irc_say(_irc_more)
	} else
		irc_say("That's it.")
	next
}
