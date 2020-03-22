# SPDX-License-Identifier: EFL-2.0 AND GPL-3.0
# Copyright (c) 2019 Max Rees
# See LICENSE for more information.
#
# The shell_quote function was adapted from:
# https://www.gnu.org/software/gawk/manual/html_node/Shell-Quoting.html
# Copyright (c) 2014 Michael Brennan
# See LICENSE.GPL3 for more information.

function load_config() {
	FS = "="

	while ((getline < ENVIRON["STAN_CFG"]) == 1) {
		if ($1 == "BRAIN_FILE")
			BRAIN_FILE = $2
		else if ($1 == "QUOTE_FILE")
			QUOTE_FILE = $2
		else if ($1 == "OWNERMASK")
			OWNERMASK = $2
		else if ($1 == "NICK")
			NICK = $2
		else if ($1 == "USERNAME")
			USERNAME = $2
		else if ($1 == "NS_PASSWORD")
			NS_PASSWORD = $2
		else if ($1 == "GECOS")
			GECOS = $2
		else if ($1 == "CMD_PATTERN")
			CMD_PATTERN = $2
		else if ($1 == "CHANNELS")
			CHANNELS[$2] = 0
		else if ($1 == "CHAT_CHANS")
			CHAT_CHANS[$2] = 0
		else if ($1 == "UNO_MASTER")
			UNO_MASTER = $2
		else if ($1 == "IGNORE")
			IGNORE[$2] = 1
		else if ($1 == "IGNOREPAT")
			IGNOREPAT[$2] = 1
		else if ($1 == "VERBOSE")
			VERBOSE = $2
		else if (index($1, "#") != 1)
			notice("Unknown configuration option: '" $1 "'")
	}

	close(ENVIRON["STAN_CFG"])
	FS = " "
}

# Return a random integer in the closed interval [lower, upper]
# since rand() returns a floating point number in the half-open
# interval [0, 1)
function randrange(lower, upper) {
	return int((upper - lower + 1) * rand()) + lower
}

function slice(array, lower, upper,        i) {
		s = ""
		for (i = lower; i <= upper; i++)
			s = s " " array[i]
		sub(/^ /, "", s)
		return s
}

function shell_quote(str,        SINGLE, QSINGLE, len, exploded, i) {
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

function get_output(argv,        output) {
	(argv) | getline output
	close(argv)
	return output
}

function record(msg) {
	print msg > "/dev/stderr"
	fflush("/dev/stderr")
}

function debug(msg) {
	if (VERBOSE != "")
		record(msg)
}

# Only print once. Useful for ensuring some output from server is seen when
# !VERBOSE, but not printed when VERBOSE
function record_once(msg) {
	if (VERBOSE == "")
		record(msg)
}

function notice(msg) {
	record("*** " msg)
}

function send(msg) {
	debug(">>> " msg)
	print msg
	fflush()
}

function say(channel, msg) {
	if (length(msg) > 450) {
		MORE[channel] = substr(msg, 451, length(msg))
		msg = substr(msg, 1, 450) " [%more]"
	}

	record_once(sprintf(">>> (%s) <%s> %s", channel, NICK, msg))
	send("PRIVMSG " channel " :" msg)
}

function irccmd(cmd, args) {
	record_once("*** " cmd " " args)
	send(cmd " " args)
}

function case_expand(c) {
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
		return "[" tolower(c) toupper(c) "]"
}

function set_nick(nick) {
	NICK = nick
	irccmd("NICK", nick)

	nick_pattern = ""
	for (i = 1; i <= length(NICK); i++) {
		c = substr(NICK, i, 1)
		c = case_expand(c)
		nick_pattern = nick_pattern c
	}

	record("Nick pattern is: " nick_pattern)

	ADDRESS_PATTERN = "^" nick_pattern "[:, ]+ ?"
	CHAT_PATTERN = "[^]^a-z0-9{}_`|\\\\])"
	CHAT_PATTERN = "(^|" CHAT_PATTERN nick_pattern "($|" CHAT_PATTERN
}

function identify() {
	if (NS_PASSWORD != "")
		send("PRIVMSG NickServ :identify " NICK " " NS_PASSWORD)
}

function age(        delta, days, hours, mins, secs) {
	delta = systime() - BIRTH
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

function randnick(channel,        i, j) {
	j = randrange(1, CHANNELS[channel])
	i = 0
	for (bangpath in NAMES) {
		i++
		split(bangpath, path, SUBSEP)
		if (i == j)
			return path[2]
	}
}

function markov(trigger, channel, msg) {
	printf "%d %s %s\n", trigger, channel, msg | MARKOV_ARGV
	fflush(MARKOV_ARGV)
}

function learn(msg,        words, i, len) {
	len = split(msg, words, " ")
	if (len < 2)
		return

	notice("Learning...")
	if (len < 3) {
		printf "%s %s\036\n", words[1], words[2] >> (BRAIN_FILE ".new")
		fflush(BRAIN_FILE ".new")
		close(BRAIN_FILE ".new")
		return
	}

	for (i = 1; i <= len - 2; i++) {
		if (i + 1 > len - 2)
			end = "\036"
		else
			end = ""
		printf "%s %s %s%s\n", words[i], words[i + 1], words[i + 2], end >> (BRAIN_FILE ".new")
	}
	fflush(BRAIN_FILE ".new")
	close(BRAIN_FILE ".new")
}

function chat(channel, nick, msg) {
	if (!(channel in CHAT_CHANS))
		return

	if (tolower(msg) ~ CHAT_PATTERN || randrange(0, 300) == 67) {
		sub(ADDRESS_PATTERN, "", msg)
		if (msg ~ "^\s*h\s*$")
			say(channel, "h")
		else
			markov(1, channel, msg)
	}

	else {
		markov(0, channel, msg)
	}

	if (!index(msg, "http") && randrange(0, 10) == 7)
		learn(msg)
}

function has_card(w_card, w_color, w_number,        color, number, card, card_v) {
	if (w_card)
		record("w_card = '" w_card "'")
	if (w_color)
		record("w_color = '" w_color "'")
	if (w_number)
		record("w_number = '" w_number "'")

	for (card in CARDS) {
		split(CARDS[card], card_v, / /)
		color = card_v[1]
		number = card_v[2]

		if (!color)
			continue

		record("CARDS[card] = " CARDS[card])
		record("color = " color)
		record("number = " number)

		if (w_card && CARDS[card] == w_card)
			return CARDS[card]
		if (w_color && color == w_color)
			return CARDS[card]
		if (w_number && number == w_number)
			return CARDS[card]
	}
	return ""
}

function decide_play(channel, new_card,        play) {
	if (new_card) {
		delete CARDS
		CARDS[1] = new_card
	}

	if (DISCARD == "Wild +4" && PLUS_TARGET) {
		play = has_card("Wild +4", "", "")
	}
	else if (D_NUMBER == "+2" && PLUS_TARGET) {
		play = has_card("", "", "+2")
		if (!play)
			play = has_card(D_COLOR " Reverse")
		if (!play)
			play = has_card("Wild +4", "", "")
	} else {
		play = has_card("", D_COLOR, "")
		if (!play)
			play = has_card("", "", D_NUMBER)
		if (!play)
			play = has_card("Wild", "", "")
		if (!play)
			play = has_card("Wild +4", "", "")
		if (!play) {
			if (new_card)
				play_card(channel, "pa")
			else
				play_card(channel, "pe")
			return
		}
	}

	if (!play && new_card)
		play = "pa"
	else if (!play && !new_card)
		play = "pe"

	play_card(channel, play)
}

function play_card(channel, card,        card_v, color, number, i, new_color) {
	if (!card) {
		say(channel, "pe")
		return
	}

	if (card == "pe" || card == "pa") {
		say(channel, card)
		return
	}

	split(card, card_v, / /)
	color = card_v[1]
	number = card_v[2]

	if (color == "Red")
		color = "r"
	else if (color == "Blue")
		color = "b"
	else if (color == "Yellow")
		color = "y"
	else if (color == "Green")
		color = "g"
	else if (color == "Wild")
		color = "w"

	if (number == "Reverse")
		number = "r"
	else if (number == "Skip")
		number = "s"

	if (color == "w") {
		i = randrange(1, 4)
		if (i == 1)
			new_color = "r"
		else if (i == 2)
			new_color = "b"
		else if (i == 3)
			new_color = "y"
		else
			new_color = "g"
	} else
		new_color = ""

	say(channel, "pl " color " " number " " new_color)
}

function uno(channel, msg,        card, discard_v, play) {
	gsub(/[\x03\x02\x1d\x1f\x16\x0f]/, "", msg)
	gsub(/01,09W00,12i01,08l00,04d01,09/, "Wild", msg)
	gsub(/00,12[+]01,08400,04/, "+4", msg)
	sub(/[ ]+$/, "", msg)

	if (msg == "it's " NICK "'s turn")
		decide_play(UNO_CHAN, "")

	else if (msg == "you can't do that, " NICK)
		say(UNO_CHAN, "pe")

	else if (msg == NICK " picks a card" || msg == NICK " passes turn")
		return

	else if (msg ~ /^next player must respond correctly/)
		PLUS_TARGET = 1

	else if (msg ~ /^You picked/) {
		sub(/^You picked/, "", msg)
		sub(/[ ]*[0-9][0-9],[0-9][0-9][ ]*/, "", msg)
		decide_play(UNO_CHAN, msg)
	}

	else if (msg ~ /^Your cards: /) {
		delete CARDS
		sub(/^Your cards: /, "", msg)
		split(msg, CARDS, /[ ]*[0-9][0-9],[0-9][0-9][ ]*/)
		for (card in CARDS) {
			if (!CARDS[card])
				continue
			record("card = '" CARDS[card] "'")
		}
	}

	else if (msg ~ /^color is now/) {
		sub(/^color is now /, "", msg)
		gsub(/[0-9][0-9],[0-9][0-9][ ]*/, "", msg)
		gsub(/[ ]+/, " ", msg)

		if (PLUS_TARGET)
			NEXT_COLOR = msg
		else {
			DISCARD = msg " *"
			D_COLOR = msg
			D_NUMBER = ""

			record("DISCARD = '" DISCARD "'")
			record("D_COLOR = '" D_COLOR "'")
			record("D_NUMBER = '" D_NUMBER "'")
		}
	}

	else if (msg ~ /has to pick/ || msg ~ /must pick/) {
		PLUS_TARGET = ""
		if (NEXT_COLOR) {
			DISCARD = NEXT_COLOR " *"
			D_COLOR = NEXT_COLOR
			D_NUMBER = ""
			NEXT_COLOR = ""

			record("DISCARD = '" DISCARD "'")
			record("D_COLOR = '" D_COLOR "'")
			record("D_NUMBER = '" D_NUMBER "'")
		}
	}

	else if (msg ~ /^Current discard: / || msg ~ / plays /) {
		sub(/^Current discard: /, "", msg)
		sub(/^.* plays /, "", msg)
		sub(/ twice!$/, "", msg)
		gsub(/[0-9][0-9],[0-9][0-9][ ]*/, "", msg)
		gsub(/[ ]+/, " ", msg)
		DISCARD = msg
		split(msg, discard_v, / /)
		D_COLOR = discard_v[1]
		D_NUMBER = discard_v[2]

		# Wild
		if (D_COLOR == "Wild" && D_NUMBER != "+4") {
			DISCARD = D_NUMBER " *"
			D_COLOR = D_NUMBER
			D_NUMBER = ""
		}
		# Wild +4 with color
		if (D_COLOR == "Wild" && D_NUMBER == "+4")
			DISCARD = "Wild +4"
		if (discard_v[3] && !PLUS_TARGET) {
			DISCARD = discard_v[3] " *"
			D_COLOR = discard_v[3]
			D_NUMBER = ""
		}
		else if (discard_v[4] && !PLUS_TARGET) {
			DISCARD = discard_v[4] " *"
			D_COLOR = discard_v[4]
			D_NUMBER = ""
		}

		record("DISCARD = '" DISCARD "'")
		record("D_COLOR = '" D_COLOR "'")
		record("D_NUMBER = '" D_NUMBER "'")
	}

	else
		chat(channel, nick, msg)
}

function grab_quote(qchan, nick, quote) {
	if (nick && !((qchan, nick) in QUOTES)) {
		say(channel, "who?")
		return
	} else if (nick)
		quote = QUOTES[qchan, nick]
	else if (qchan && (qchan in QUOTES))
		quote = QUOTES[qchan]
	else if (quote)
		quote = quote
	else {
		say(channel, "huh?")
		return
	}

	print quote >> (QUOTE_FILE)
	fflush(QUOTE_FILE)
	say(channel, "Quote added")
}

function rand_quote(search,        argv, quote) {
	if (search) {
		argv = "grep -F " shell_quote(search) " " shell_quote(QUOTE_FILE)
		argv = argv " | shuf -n1 "
	} else
		argv = "shuf -n1 " shell_quote(QUOTE_FILE)

	argv | getline quote
	close(argv)
	if (!quote)
		say(channel, "No results")
	else
		say(channel, quote)
}

function admin(channel, nick, cmd, cmdlen,        bangpath, path) {
	if (cmd[1] == "sync")
		irccmd("WHOIS", NICK)

	else if (cmd[1] == "identify")
		identify()

	else if (cmd[1] == "restart") {
		say(channel, "Killing child #" CHILD)
		notice("****** STOPPING CHILD #" CHILD " ******")
		exit 69
	}

	else if (cmd[1] == "chat")
		CHAT_CHANS[channel] = 0

	else if (cmd[1] == "quiet")
		delete CHAT_CHANS[channel]

	else if (cmd[1] == "quit")
		irccmd("QUIT", ":See ya later")

	else if (cmdlen == 2) {
		if (cmd[1] == "join") {
			CHANNELS[cmd[2]] = 0
			irccmd("JOIN", cmd[2])
		}

		else if (cmd[1] == "part") {
			delete CHANNELS[cmd[2]]
			irccmd("PART", cmd[2] " :See ya later")
		}

		else if (cmd[1] == "nick")
			set_nick(cmd[2])
	}

	else if (cmd[1] == "say" && cmdlen > 2)
		send("PRIVMSG " cmd[2] " :" slice(cmd, 3, cmdlen))
}

function user(channel, nick, cmd, cmdlen,        msg) {
	if (cmd[1] == "status") {
		msg = "Child #" CHILD ": " age() " old with " NR " messages read"
		say(channel, msg)
	}

	else if (cmd[1] == "more") {
		if (MORE[channel]) {
			msg = MORE[channel]
			MORE[channel] = ""
			say(channel, msg)
		} else
			say(channel, "That's it.")
	}

	else if (cmd[1] == "uptime")
		say(channel, get_output("uptime"))

	else if (cmd[1] == "police") {
		if (cmd[2] == "ON")
			POLICE="ON"
		else if (cmd[2] == "OFF")
			POLICE="OFF"
		else if (cmd[2] == "ON_FULLPOWER")
			POLICE="ON_FULLPOWER"

		if (POLICE == "")
			POLICE="OFF"

		say(channel, "POLICE:" POLICE)
	}

	else if (cmd[1] == "nsa") {
		say(channel, "Do skype,yahoo other chat and social communication prog work 2 spoil muslims youth and spy 4 isreal&usa???????")
		say(channel, "do they record and analyse every word we type????????????")
	}

	else if (cmd[1] == "cocain") {
		if (cmd[2])
			target = cmd[2]
		else
			target = randnick(channel)

		say(channel, "i fucking hate " target ". i bet they cnt evil lift many miligram of cocain with penis")
	}

	else if (cmd[1] == "uno") {
		if (cmd[2])
			UNO_CHAN = cmd[2]
		else
			UNO_CHAN = channel
		say(UNO_CHAN, "jo")
	}

	else if (cmd[1] == "add" && cmd[2])
		grab_quote("", "", slice(cmd, 2, cmdlen))

	else if (cmd[1] == "grab") {
		if (cmd[2])
			grab_quote(channel, cmd[2])
		else
			grab_quote(channel)
	}

	else if (cmd[1] == "rand") {
		if (cmd[2])
			rand_quote(slice(cmd, 2, cmdlen))
		else
			rand_quote()
	}
}

BEGIN {
	load_config()
	srand()
	RS = "\n"
	FS = " "

	if (CHILD == "") {
		if (ENVIRON["STAN_ARGV"] == "") {
			notice("The $STAN_ARGV environment variable must be defined")
			exit 1
		}

		argv = ENVIRON["STAN_ARGV"] " -v CHILD="
		child_number = 1
		child_status = system(argv child_number)
		while (child_status == 69) {
			child_number++
			child_status = system(argv child_number)
		}
		exit child_status
	}

	notice("****** STARTING CHILD #" CHILD " ******")
	BIRTH = systime()
	MARKOV_ARGV = "python3 markov.py " shell_quote(BRAIN_FILE)
	set_nick(NICK)

	if (CHILD == "1")
		irccmd("USER", USERNAME " 8 * :" GECOS)

	else {
		delete CHANNELS
		delete NAMES
		irccmd("WHOIS", NICK)
	}
}

{
	debug("<<< " $0)
	# Normally we'd just add \r to RS, but mawk ignores RS with -W interactive
	# so let's strip it out manually instead
	sub(/\r$/, "")
}

/^PING :/ {
	send("PONG " $2)
}

# Welcome message - usually safe to join now
$2 ~ /^001$/ {
	notice("Connected!")
	identify()
	for (channel in CHANNELS)
		irccmd("JOIN", channel)
}

# Display errors from the server (4xx, 5xx, and sometimes 9xx numerics)
$2 ~ /^[459][0-9][0-9]/ {
	record_once("<<< " $0)
}

# WHOIS
#    $1   $2   $3   $4     $5      $6      $7
# :server 319 NICK nick :#chan1 +#chan2 @#chan3
$2 ~ /^319$/ {
	if ($4 == NICK) {
		for (i = 5; i <= NF; i++) {
			channel = $(i)
			sub(/[:+@]+/, "", channel)
			CHANNELS[channel] = 0
			irccmd("NAMES", channel)
		}
	}
}

# NAMES
#    $1   $2   $3    $4     $5      $6     $7     $8
# :server 353 NICK [@*=] #channel :nick1 +nick2 @nick3
$2 ~ /^353$/ {
	channel = $5

	# Clear old NAMES first
	CHANNELS[channel] = 0
	for (bangpath in NAMES) {
		split(bangpath, path, SUBSEP)
		if (path[1] == channel)
			delete NAMES[bangpath]
	}

	s = ""
	for (i = 6; i <= NF; i++) {
		nick = $(i)
		sub(/[:+@]+/, "", nick)
		s = s " " nick
		if (!((channel, nick) in NAMES)) {
			CHANNELS[channel] += 1
			NAMES[channel, nick] = 1
		}
	}

	record_once("NAMES " channel " (" CHANNELS[channel] "):" s)
}

# JOIN
#       $1         $2     $3
# :nick!user@host JOIN #channel
# PART
#       $1         $2     $3
# :nick!user@host PART #channel :msg
# KICK
#       $1         $2     $3     $4
# :nick!user@host KICK #channel nick :msg
# QUIT
#       $1         $2
# :nick!user@host QUIT :msg
$2 ~ /^(JOIN|PART|QUIT)$/ {
	bang = index($1, "!")
	if (!bang)
		next
	nick = substr($1, 2, bang - 2)
	if (nick == NICK)
		next
	channel = $3

	if ($2 == "JOIN") {
		CHANNELS[channel] += 1
		NAMES[channel, nick] = 1
	}

	else if ($2 == "PART") {
		CHANNELS[channel] -= 1
		delete NAMES[channel, nick]
	}

	else if ($2 == "KICK") {
		nick = $4
		CHANNELS[channel] -= 1
		delete NAMES[channel, nick]
	}

	else {
		for (bangpath in NAMES) {
			split(bangpath, path, SUBSEP)
			if (path[2] == nick) {
				CHANNELS[channel] -= 1
				delete NAMES[bangpath]
			}
		}
	}
}

#       $1          $2       $3     $4
# :nick!user@host PRIVMSG #channel :msg
$2 ~ /^(PRIVMSG|NOTICE)$/ {
	bang = index($1, "!")
	if (!bang)
		next
	nick = substr($1, 2, bang - 2)
	hostmask = substr($1, bang + 1)
	channel = $3
	msgstart = length($1 " " $2 " " $3 " :") + 1
	msg = substr($0, msgstart)

	if (channel == NICK) {
		channel = nick
		fmt = "(" nick ")"
	} else
		fmt = "(" channel ") <" nick ">"

	for (pattern in IGNOREPAT)
		if (msg ~ pattern) {
			record_once(sprintf("~~~ %s %s", fmt, msg))
			next
		}

	if (nick in IGNORE || nick == NICK) {
		record_once(sprintf("~~~ %s %s", fmt, msg))
		next
	} else
		record_once(sprintf("<<< %s %s", fmt, msg))

	if (msg ~ CMD_PATTERN) {
		sub(CMD_PATTERN, "", msg)
		cmdlen = split(msg, cmd, " ")

		if (hostmask == OWNERMASK)
			admin(channel, nick, cmd, cmdlen)

		user(channel, nick, cmd, cmdlen)
	}

	else if (nick == UNO_MASTER)
		uno(channel, msg)

	else
		chat(channel, nick, msg)
}

END {
	close(MARKOV_ARGV)
}
