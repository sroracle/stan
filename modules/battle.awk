# SPDX-License-Identifier: EFL-2.0 AND BSD-3-Clause
# Copyright (c) 2019-2021 Max Rees
# See LICENSE for more information.
#
# Adapted from Eren Zie's "fishbot", presumably under the 3-clause BSD
# License as that is the license of its successor supybot plugin.
# See LICENSE.BSD3 for more information.

function battle_damage(target, damage) {
	if (!(target in BATTLE) || BATTLE[target] <= 0)
	    BATTLE[target] = 10000

	if (damage >= BATTLE[target])
		BATTLE[target] = 0
	else
		BATTLE[target] -= damage
}

function battle_do_action(can_miss) {
	BATTLE_CRITICAL = util_randrange(1, 100) > 90
	if (BATTLE_CRITICAL)
		BATTLE_DAMAGE = util_randrange(3000, 10000)
	else
		BATTLE_DAMAGE = util_randrange(1, 3000)

	BATTLE_MISSED = 0
	if (can_miss) {
		BATTLE_MISSED = util_randrange(1, 100) > 90
		if (BATTLE_MISSED)
			BATTLE_DAMAGE = 0
	}

	battle_damage(BATTLE_TARGET, BATTLE_DAMAGE)
}

function battle_do_attack(        i) {
	battle_do_action(1)
	if (BATTLE_MISSED) {
		i = util_randrange(1, 3)
		if (i == 1)
			irc_say("MISS!")
		else if (i == 2)
			irc_say(BATTLE_TARGET" is immune to "BATTLE_WEAPON)
		else
			irc_say("\001ACTION calls the police\001")
		return
	}
	if (BATTLE[BATTLE_TARGET] == 0) {
		if (BATTLE_CRITICAL)
			irc_say(BATTLE_TARGET" is \002CRITICALLY HIT\002 to \002DEATH\002 by "BATTLE_WEAPON", taking "BATTLE_DAMAGE" damage! RIP")
		else
			irc_say(BATTLE_TARGET" is fatally injured by "BATTLE_WEAPON", taking "BATTLE_DAMAGE" damage. RIP")
		return
	}
	if (BATTLE_CRITICAL)
		return BATTLE_TARGET" is \002CRITICALLY HIT\002 by "BATTLE_WEAPON", taking "BATTLE_DAMAGE" damage!"
	if (BATTLE_DAMAGE > 1500)
		return BATTLE_TARGET" is tremendously damaged by "BATTLE_WEAPON", taking "BATTLE_DAMAGE" damage!"
	if (BATTLE_DAMAGE < 200)
		return BATTLE_TARGET" barely even felt "BATTLE_WEAPON", taking "BATTLE_DAMAGE" damage."
	return BATTLE_TARGET" takes "BATTLE_DAMAGE" from "BATTLE_WEAPON"."
}

function battle_match_plural(thing) {
	if (thing ~ /(penis|cactus)$/)
		return "s"
	if (thing ~ /cacti$/)
		return ""
	if (thing ~ /[^']s$/)
		return ""
	return "s"
}

function battle_do_throw(        old_target, maybe_person, to_both, orig_hp, response, s) {
	battle_do_action(1)
	if (BATTLE_MISSED) {
		old_target = BATTLE_TARGET
		BATTLE_TARGET = irc_rand_nick(irc_channel)
		battle_do_action(0)
		return BATTLE_ATTACKER" missed "old_target" and instead hit "BATTLE_TARGET", dealing "BATTLE_DAMAGE" damage!"
	}
	if (BATTLE[BATTLE_TARGET] == 0) {
		irc_say(BATTLE_WEAPON" hit "BATTLE_TARGET" so hard that they fell over and died, taking "BATTLE_DAMAGE" damage. RIP")
		return
	}

	maybe_person = BATTLE_WEAPON
	to_both = ""
	sub(/^the /, "", maybe_person)
	if ((irc_channel, maybe_person) in IRC_NAMES) {
		to_both = " to both"
		orig_hp = BATTLE[BATTLE_TARGET]
		battle_damage(maybe_person, BATTLE_DAMAGE)
	}
	else
		maybe_person = ""

	response = ""
	s = battle_match_plural(BATTLE_WEAPON)
	if (BATTLE_DAMAGE > 1500)
		response = BATTLE_WEAPON" severely injure"s" "BATTLE_TARGET", dealing "BATTLE_DAMAGE" HP"to_both"!"
	else if (BATTLE_DAMAGE < 200)
		response = BATTLE_WEAPON" barely hit "BATTLE_TARGET", dealing "BATTLE_DAMAGE" HP"to_both"."
	else
		response = BATTLE_WEAPON" thwack"s" "BATTLE_TARGET" in the face, dealing "BATTLE_DAMAGE" HP"to_both"."

	if (maybe_person) {
		irc_say(response" "BATTLE_TARGET" now has "orig_hp" HP, and "maybe_person" now has "BATTLE[maybe_person]" HP.")
		return
	}
	return response
}

function battle_do_cast() {
	battle_do_action(1)

	# Huh?
	if (BATTLE_WEAPON !~ /'s/)
		sub(/^the /, "", BATTLE_WEAPON)

	if (BATTLE_MISSED) {
		irc_say("You failed at casting...")
		return
	}
	if (BATTLE[BATTLE_TARGET] == 0) {
		irc_say(BATTLE_ATTACKER" casts a fatal spell of "BATTLE_WEAPON" at "BATTLE_TARGET", dealing "BATTLE_DAMAGE" damage. RIP")
		return
	}
	return BATTLE_ATTACKER" casts "BATTLE_WEAPON" at "BATTLE_TARGET", dealing "BATTLE_DAMAGE" damage."
}

function battle_do_heal(        response, with_tool, maim_self, fatal_self) {
	BATTLE_DAMAGE = util_randrange(1, 1500)

	BATTLE_MISSED = util_randrange(1, 100) > 50
	BATTLE_BACKFIRED = 0
	if (BATTLE_MISSED) {
		BATTLE_BACKFIRED = util_randrange(1, 100) > 70
		if (BATTLE_BACKFIRED) {
			battle_damage(BATTLE_ATTACKER, BATTLE_DAMAGE)
		}
	} else {
		battle_damage(BATTLE_TARGET, -BATTLE_DAMAGE)
	}

	if (BATTLE_WEAPON) {
		with_tool = " with "BATTLE_WEAPON
		maim_self = BATTLE_WEAPON" hurt "BATTLE_ATTACKER
		fatal_self = BATTLE_WEAPON" KILLED "BATTLE_ATTACKER
	} else {
		with_tool = ""
		maim_self = BATTLE_ATTACKER" hurt themself"
		fatal_self = BATTLE_ATTACKER" KILLED themself"
	}

	if (BATTLE_BACKFIRED && BATTLE[BATTLE_ATTACKER] == 0) {
		irc_say("In a freak accident, "fatal_self" with "BATTLE_DAMAGE" damage instead of healing "BATTLE_TARGET"!")
		return
	}
	if (BATTLE_BACKFIRED) {
		response = "In a freak accident, "maim_self" for "BATTLE_DAMAGE" damage instead of healing "BATTLE_TARGET"!"
		BATTLE_TARGET = BATTLE_ATTACKER
		return response
	}
	if (BATTLE_MISSED) {
		irc_say(BATTLE_ATTACKER" tried to heal "BATTLE_TARGET with_tool", however they failed. :(")
		return
	}
	return BATTLE_ATTACKER" managed to heal "BATTLE_TARGET" for "BATTLE_DAMAGE" HP"with_tool"!"
}

function battle_get_phrases(        type, sep, i) {
	BATTLE_ACTION = irc_msgv[2]
	type = BATTLE_WORDS[BATTLE_ACTION]
	sep = ""
	for (i = 3; i <= irc_msgv_len; i++)
		if ((BATTLE_ACTION, irc_msgv[i]) in BATTLE_WORDS) {
			sep = irc_msgv[i]
			break
		}

	# Separator required for type 0 (redirects to a type 2 or 3).
	if (type == 0 && !sep)
		return 0
	if (sep)
		type = BATTLE_WORDS[BATTLE_ACTION, sep]

	BATTLE_TARGET = ""
	BATTLE_WEAPON = ""
	if (type == 1)
		BATTLE_TARGET = util_array_slice(irc_msgv, 3, irc_msgv_len)
	else if (type == 2) {
		BATTLE_TARGET = util_array_slice(irc_msgv, 3, i - 1)
		BATTLE_WEAPON = util_array_slice(irc_msgv, i + 1, irc_msgv_len)
	} else if (type == 3) {
		BATTLE_WEAPON = util_array_slice(irc_msgv, 3, i - 1)
		BATTLE_TARGET = util_array_slice(irc_msgv, i + 1, irc_msgv_len)
	}

	return 1
}

function battle_sanitize_target() {
	if (BATTLE_TARGET ~ /^(him|her|its|eir|zir|hir|their|them|)self$/ || BATTLE_TARGET == "themselves")
		BATTLE_TARGET = BATTLE_ATTACKER
}

function battle_sanitize_weapon(        pronouns) {
	pronouns = BATTLE_WEAPON ~ /^(his|her|its|eir|zir|hir|their) /
	if (pronouns)
		sub(/^[^ ]+ /, "", BATTLE_WEAPON)
	else
		sub(/^an? /, "", BATTLE_WEAPON)

	if (BATTLE_WEAPON && BATTLE_WEAPON !~ /^the / && BATTLE_WEAPON !~ /'s/) {
		if (pronouns)
			BATTLE_WEAPON = BATTLE_ATTACKER"'s "BATTLE_WEAPON
		else
			BATTLE_WEAPON = "the "BATTLE_WEAPON
	}

	if (!BATTLE_WEAPON) {
		if (BATTLE_ACTION == "fites")
			BATTLE_WEAPON = "the 1v1 fite irl"
		else if (BATTLE_ACTION == "attacks" || BATTLE_ACTION == "stabs")
			BATTLE_WEAPON = "the knife"
	} else if (BATTLE_ACTION == "drops" && BATTLE_WEAPON == "the bass")
		BATTLE_WEAPON = "the dubstep"
}

function battle(        i, response, old_target, with_tool, maim_self, fatal_self) {
	if (!battle_get_phrases())
		return

	BATTLE_ATTACKER = irc_nick
	battle_sanitize_target()
	battle_sanitize_weapon()

	response = ""
	if (BATTLE_ACTION ~ /^(attacks|stabs|fites)$/) {
		response = battle_do_attack()
	} else if (BATTLE_ACTION ~ /^(throws|drops|thwacks)$/) {
		response = battle_do_throw()
	} else if (BATTLE_ACTION == "casts") {
		response = battle_do_cast()
	} else if (BATTLE_ACTION == "heals")
		response = battle_do_heal()

	if (response) {
		response = response" They now have "BATTLE[BATTLE_TARGET]" HP."
		irc_say(response)
	}
}

BEGIN {
	# Type 0: redirect to type 2 or 3
	# Type 1: <action> <target>
	# Type 2: <action> <target> <separator> <weapon>
	# Type 3: <action> <weapon> <separator> <target> (reverse of type 2)
	BATTLE_WORDS["attacks"] = 1
	BATTLE_WORDS["attacks", "with"] = 2

	BATTLE_WORDS["stabs"] = 1
	BATTLE_WORDS["stabs", "with"] = 2

	BATTLE_WORDS["fites"] = 1
	BATTLE_WORDS["fites", "with"] = 2

	BATTLE_WORDS["throws"] = 1
	BATTLE_WORDS["throws", "at"] = 3

	BATTLE_WORDS["drops"] = 1
	BATTLE_WORDS["drops", "on"] = 3

	BATTLE_WORDS["thwacks"] = 1
	BATTLE_WORDS["thwacks", "with"] = 2

	BATTLE_WORDS["casts"] = 0
	BATTLE_WORDS["casts", "at"] = 3
	BATTLE_WORDS["casts", "on"] = 3

	BATTLE_WORDS["heals"] = 1
	BATTLE_WORDS["heals", "with"] = 2
}

irc_channel in BATTLE_CHANNELS && irc_msg ~ "^\001ACTION .*\001$" && irc_msgv[2] in BATTLE_WORDS {
	sub(/\001$/, "", irc_msgv[irc_msgv_len])
	battle()
	next
}
