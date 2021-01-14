# SPDX-License-Identifier: EFL-2.0
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.

function uno_has_card(w_card, w_color, w_number,        color, number, card, card_v) {
	if (w_card)
		log_info("w_card = '"w_card"'")
	if (w_color)
		log_info("w_color = '"w_color"'")
	if (w_number)
		log_info("w_number = '"w_number"'")

	for (card in UNO_CARDS) {
		split(UNO_CARDS[card], card_v, / /)
		color = card_v[1]
		number = card_v[2]

		if (!color)
			continue

		log_info("UNO_CARDS[card] = "UNO_CARDS[card])
		log_info("color = "color)
		log_info("number = "number)

		if (w_card && UNO_CARDS[card] == w_card)
			return UNO_CARDS[card]
		if (w_color && color == w_color)
			return UNO_CARDS[card]
		if (w_number && number == w_number)
			return UNO_CARDS[card]
	}
	return ""
}

function uno_decide_play(new_card,        play) {
	if (new_card) {
		delete UNO_CARDS
		UNO_CARDS[1] = new_card
	}

	if (UNO_DISCARD == "Wild +4" && UNO_PLUS_TARGET) {
		play = uno_has_card("Wild +4", "", "")
	}
	else if (UNO_D_NUMBER == "+2" && UNO_PLUS_TARGET) {
		play = uno_has_card("", "", "+2")
		if (!play)
			play = uno_has_card(UNO_D_COLOR" Reverse")
		if (!play)
			play = uno_has_card("Wild +4", "", "")
	} else {
		play = uno_has_card("", UNO_D_COLOR, "")
		if (!play)
			play = uno_has_card("", "", UNO_D_NUMBER)
		if (!play)
			play = uno_has_card("Wild", "", "")
		if (!play)
			play = uno_has_card("Wild +4", "", "")
		if (!play) {
			if (new_card)
				uno_play_card("pa")
			else
				uno_play_card("pe")
			return
		}
	}

	if (!play && new_card)
		play = "pa"
	else if (!play && !new_card)
		play = "pe"

	uno_play_card(play)
}

function uno_play_card(card,        card_v, color, number, i, new_color) {
	if (!card) {
		irc_tell(UNO_CHAN, "pe")
		return
	}

	if (card == "pe" || card == "pa") {
		irc_tell(UNO_CHAN, card)
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
		i = util_randrange(1, 4)
		if (i == 1)
			new_color = "r"
		else if (i == 2)
			new_color = "b"
		else if (i == 3)
			new_color = "y"
		else
			new_color = "g"
	}

	irc_tell(UNO_CHAN, "pl "color" "number" "new_color)
}

function uno(msg,        card, discard_v, play) {
	gsub(/[\x03\x02\x1d\x1f\x16\x0f]/, "", irc_msg)
	gsub(/01,09W00,12i01,08l00,04d01,09/, "Wild", irc_msg)
	gsub(/00,12[+]01,08400,04/, "+4", irc_msg)
	sub(/[ ]+$/, "", irc_msg)

	if (irc_msg == "it's "IRC_NICK"'s turn")
		uno_decide_play()

	else if (irc_msg == "you can't do that, "IRC_NICK)
		irc_tell(UNO_CHAN, "pe")

	else if (irc_msg == IRC_NICK" picks a card" || irc_msg == IRC_NICK" passes turn")
		return

	else if (irc_msg ~ /^next player must respond correctly/)
		UNO_PLUS_TARGET = 1

	else if (irc_msg ~ /^You picked/) {
		sub(/^You picked/, "", irc_msg)
		sub(/[ ]*[0-9][0-9],[0-9][0-9][ ]*/, "", irc_msg)
		uno_decide_play(irc_msg)
	}

	else if (irc_msg ~ /^Your cards: /) {
		delete UNO_CARDS
		sub(/^Your cards: /, "", irc_msg)
		split(irc_msg, UNO_CARDS, /[ ]*[0-9][0-9],[0-9][0-9][ ]*/)
		for (card in UNO_CARDS) {
			if (!UNO_CARDS[card])
				continue
			log_info("card = '"UNO_CARDS[card]"'")
		}
	}

	else if (irc_msg ~ /^color is now/) {
		sub(/^color is now /, "", irc_msg)
		gsub(/[0-9][0-9],[0-9][0-9][ ]*/, "", irc_msg)
		gsub(/[ ]+/, " ", irc_msg)

		if (UNO_PLUS_TARGET)
			UNO_NEXT_COLOR = irc_msg
		else {
			UNO_DISCARD = irc_msg" *"
			UNO_D_COLOR = irc_msg
			UNO_D_NUMBER = ""

			log_info("UNO_DISCARD = '"UNO_DISCARD"'")
			log_info("UNO_D_COLOR = '"UNO_D_COLOR"'")
			log_info("UNO_D_NUMBER = '"UNO_D_NUMBER"'")
		}
	}

	else if (irc_msg ~ /has to pick/ || irc_msg ~ /must pick/) {
		UNO_PLUS_TARGET = ""
		if (UNO_NEXT_COLOR) {
			UNO_DISCARD = UNO_NEXT_COLOR" *"
			UNO_D_COLOR = UNO_NEXT_COLOR
			UNO_D_NUMBER = ""
			UNO_NEXT_COLOR = ""

			log_info("UNO_DISCARD = '"UNO_DISCARD"'")
			log_info("UNO_D_COLOR = '"UNO_D_COLOR"'")
			log_info("UNO_D_NUMBER = '"UNO_D_NUMBER"'")
		}
	}

	else if (irc_msg ~ /^Current discard: / || irc_msg ~ / plays /) {
		sub(/^Current discard: /, "", irc_msg)
		sub(/^.* plays /, "", irc_msg)
		sub(/ twice!$/, "", irc_msg)
		gsub(/[0-9][0-9],[0-9][0-9][ ]*/, "", irc_msg)
		gsub(/[ ]+/, " ", irc_msg)
		UNO_DISCARD = irc_msg
		split(irc_msg, discard_v, / /)
		UNO_D_COLOR = discard_v[1]
		UNO_D_NUMBER = discard_v[2]

		# Wild
		if (UNO_D_COLOR == "Wild" && UNO_D_NUMBER != "+4") {
			UNO_DISCARD = UNO_D_NUMBER" *"
			UNO_D_COLOR = UNO_D_NUMBER
			UNO_D_NUMBER = ""
		}
		# Wild +4 with color
		if (UNO_D_COLOR == "Wild" && UNO_D_NUMBER == "+4")
			UNO_DISCARD = "Wild +4"
		if (discard_v[3] && !UNO_PLUS_TARGET) {
			UNO_DISCARD = discard_v[3]" *"
			UNO_D_COLOR = discard_v[3]
			UNO_D_NUMBER = ""
		}
		else if (discard_v[4] && !UNO_PLUS_TARGET) {
			UNO_DISCARD = discard_v[4]" *"
			UNO_D_COLOR = discard_v[4]
			UNO_D_NUMBER = ""
		}

		log_info("UNO_DISCARD = '"UNO_DISCARD"'")
		log_info("UNO_D_COLOR = '"UNO_D_COLOR"'")
		log_info("UNO_D_NUMBER = '"UNO_D_NUMBER"'")
	}

	else
		chat(UNO_CHAN, irc_msg)
}

irc_cmd == "uno" {
	if (irc_msgv[2])
		UNO_CHAN = irc_msgv[2]
	else
		UNO_CHAN = irc_channel
	irc_tell(UNO_CHAN, "jo")
	next
}

(irc_channel == UNO_CHAN || irc_channel == UNO_MASTER) && irc_nick == UNO_MASTER && irc_msg {
	uno()
	next
}
