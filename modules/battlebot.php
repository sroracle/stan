<?php

class bdBattle {
    var $players = array();
    var $playersnames = array(); // i'm bad


    function addPlayer($player) {
        /* Adds a player to the game
         *
         * $player - player to add to the game
         */
        if (in_array($player, $this->playersnames)) {
            return false;
        } else {
            $this->players[] = array("name" => $player, "health" => 10000);
            $this->playersnames[] = $player;
            return true;
        }
    }

    function checkPlayerInGame($player) {
        /* Checks if a player is currently in the game */
        if (!in_array($player, $this->playersnames)) {
            return false;
        } else {
            return true;
        }
    }

    function damagePlayer($player, $damage) {
        /* Deals damage to a player
         *
         * $player - player to deal damage to
         * $damage - amount of damage to deal
         *
         * returns player's health after the damage is dealt, 0 if player is dead
         */
        if (!$this->checkPlayerInGame($player)) {
            return false;
        } else {
            $id = $this->getPlayerId($this->players, $player);
            $health = $this->players[$id]["health"];

            // check if damage >= health
            if ($damage >= $health) {
                $newhealth = 0;
            } else {
                $newhealth = $health - $damage;
            }

            $this->players[$id]["health"] = $newhealth;

            return $newhealth;
        }
    }

    function getPlayerId($haystack, $needle) {
        /* Returns the id of a player in the players array
         *
         * $haystack - should only ever be $this->players, idk why i don't hardcode that in
         * $needle - name of the player to search for
         */
        $i = 0;

        if (!in_array($needle, $this->playersnames)) {
            return false;
        }

        foreach ($haystack as $playerarray) {
            if ($playerarray["name"] == $needle) {
                return $i;
            }
            $i++;
        }
    }

    function getCleanWepName($weapon) {
        if (!$weapon)
            return $weapon;
        /* Cleans the name of what someone's attacking someone with */
        $sweapon = explode(" ", $weapon);
        // check for a/an
        if ($sweapon[0] == "a") {
            $weapon = substr($weapon, 2);
        } elseif ($sweapon[0] == "an") {
            $weapon = substr($weapon, 3);
        }
        // check for his/her/its/their/eir/zir (yes. all of those.)
        switch ($sweapon[0]) {
            case "his":
            case "her":
            case "its":
            case "eir":
            case "zir":
            case "hir":
                $weapon = substr($weapon, 4);
                $pronounused = 1;
                break;
            case "their":
                $weapon = substr($weapon, 6);
                $pronounused = 1;
                break;

            default:
                $pronounused = 0;
        }

        // /me attacks blah with the blah
        // /me attacks blah with blah's blah
        // /me attacks blah with their blah
        // /me attacks blah with their blah's blah
        // check for "the"
        if ($sweapon[0] !== "the") {
            // check for 's
            if (!stristr($weapon, "'s")) {
                // no 's, add the
                if ($pronounused) {
                    $weapon = "{$this->attacker}'s {$weapon}";
                } else {
                    $weapon = "the " . $weapon;
                }
            }
        }

        return $weapon;
    }

    function getCleanToolName($tool) {
        if (!$tool)
            return $tool;
        /* getCleanWepName() but for healing; too lazy to change $weapon */
        $stool = explode(" ", $tool);
        // check for a/an/the
        if ($stool[0] == "a") {
            $tool = substr($tool, 2);
        } elseif ($stool[0] == "an") {
            $tool = substr($tool, 3);
        } elseif ($stool[0] == "the") {
            $tool = substr($tool, 4);
        }

        // check for his/her/its/their/eir/zir (yes. all of those.)
        switch ($stool[0]) {
            case "his":
            case "her":
            case "its":
            case "eir":
            case "zir":
            case "hir":
                $pronounused = 1;
                break;
            case "their":
                $pronounused = 1;
                break;

            default:
                $pronounused = 0;
        }

        return $tool;
    }

    function doRespawn($player) {
        /* Resets the health of a player to 10,000 */

        $id = $this->getPlayerId($this->players, $player);
        $this->players[$id]["health"] = 10000;
    }

    function checkIsVictimSelf($victim) {
        switch ($victim) {
            case "himself":
            case "herself":
            case "itself":
            case "eirself":
            case "zirself":
            case "hirself":
            case "theirself":
            case "themself":
            case "themselves":
            case "self":
                return true;

            default:
                return false;
        }
    }

    function doAttacking($attacker, $victim, $weapon, $nofail = false) {
        $victim = trim($victim);
        $weapon = trim($weapon);
        /* Does all the attacking of stuff and returns an array with the following:
         * [0]/["type"] = type of result: normal, fatalNormal, crit, fatalCrit, miss
         * [1]/["dmg"] = damage done
         * [2]/["hp"] = victim's new health
         * [3]/["wep"] = clean weapon name */

        $result = array();

        if (!$this->checkPlayerInGame($attacker)) {
            // attacker isn't in game, add them
            $this->addPlayer($attacker);
        }

        if (!$this->checkPlayerInGame($victim)) {
            // victim isn't in game, add them
            $this->addPlayer($victim);
        }

        $weapon = $this->getCleanWepName($weapon);

        $decideIfCrit = rand(1, 100);
        if ($decideIfCrit > 90) {
            $isCrit = true;
        } else {
            $isCrit = false;
        }

        if ($isCrit) {
            $damagetodeal = rand(3000, 10000);
        } else {
            $damagetodeal = rand(1, 3000);
        }

        if (!$nofail) {
            $decideIfMiss = rand(1, 100);
            if ($decideIfMiss > 90) {
                $isMiss = true;
                $damagetodeal = 0;
            } else {
                $isMiss = false;
            }
        } else {
            $isMiss = false;
        }

        $attackedhp = $this->damagePlayer($victim, $damagetodeal);

        if ($isMiss) {
            $result["type"] = "miss";
        } elseif ($isCrit && $attackedhp !== 0) {
            $result["type"] = "crit";
        } elseif ($isCrit && $attackedhp == 0) {
            $result["type"] = "fatalCrit";
        } elseif (!$isCrit && $attackedhp !== 0) {
            $result["type"] = "normal";
        } elseif (!$isCrit && $attackedhp == 0) {
            $result["type"] = "fatalNormal";
        }

        $result["dmg"] = $damagetodeal;
        $result["hp"] = $attackedhp;
        $result["wep"] = $weapon;

        return $result;
    }

    function checkAttkMatch($regex, $string, $nick, $altorder = false) {
        /* $altorder = true; for "/me throws <weapon> at <victim"
         * $altorder = false; for "/me attacks <victim> with <weapon>" */

        /* /^\001ACTION attacks (.*) with (.*)\001$/i
         * /^\001ACTION throws (.*) at (.*)\001$/i */
        // /^\001ACTION {$text}\001$/i
        if (preg_match("/^\001ACTION {$regex}\001$/i", $string, $blah)) {
            $this->attacker = $nick;
            if ($altorder) {
                $victim = $blah[2];
            } else {
                $victim = $blah[1];
            }
            $this->victim = trim($victim);
            if ($this->checkIsVictimSelf($victim)) {
                $this->victim = $nick;
            }
            if ($altorder) {
                $this->weapon = $blah[1];
            } else {
                $this->weapon = $blah[2];
            }

            return true;
        } else {
            $this->attacker = null;
            $this->victim = null;
            $this->weapon = null;

            return false;
        }
    }

    function checkForHealCmd($string, $nick) {
        if (preg_match("/^\001ACTION heals ([^ ]*)(?: with (.*))?\001$/i", $string, $blah)) {
            $this->healer = $nick;
            $this->patient = trim($blah[1]);
            if ($this->checkIsVictimSelf($this->patient)) {
                $this->patient = $nick;
            }
            $this->tool = $blah[2];
            return true;
        } else {
            $this->healer = null;
            $this->patient = null;
            $this->tool = null;
            return false;
        }
    }

    function doHealing($patient, $healer, $tool) {
        /* Heals a player and returns an array with the following:
         * [0]/["type"] = type of result: fail or success
         * [1]/["healing"] = amount of healing done
         * [2]/["hp"] = victim's new health
         * [3]/["tool"] = "clean" tool name */
        $healer = trim($healer);
        $patient = trim($patient);
        $tool = trim($tool);

        $result = array();

        if (!$this->checkPlayerInGame($patient)) {
            // attacker isn't in game, add them
            $this->addPlayer($patient);
        }

        if (!$this->checkPlayerInGame($healer)) {
            // victim isn't in game, add them
            $this->addPlayer($healer);
        }

        $tool = $this->getCleanToolName($tool);

        $toheal = rand(1, 1500);

        $decideIfSuccess = rand(1, 100);
        if ($decideIfSuccess < 50) {
            $isSuccess = true;
        } else {
            $isSuccess = false;
        }

        if ($isSuccess) {
            $newhp = $this->damagePlayer($patient, "-" . $toheal);
            $result['type'] = "success";
        } else {
            // decide if it should backfire or just fail
            $decideIfBackfire = rand(1, 100);
            if ($decideIfBackfire > 70) {
                // backfire!
                $newhp = $this->damagePlayer($healer, $toheal);
                if ($newhp == 0) {
                    $result['type'] = "fatalbackfire";
                } else {
                    $result['type'] = "backfire";
                }
            } else {
                $toheal = 0;
                $newhp = $this->damagePlayer($patient, 0);
                $result['type'] = "fail";
            }
        }

        $result["healing"] = $toheal;
        $result["hp"] = $newhp;
        $result["tool"] = $tool;

        return $result;
    }

    function they_now($player, $type) {
        if ($type == 1) {
            return "They now have";
        } elseif ($type == 2) {
            return "they have";
        } elseif ($type == 3) {
            return "they";
        }
    }

}

function isPlural($thing) {
    $maybepenis = explode(" ", $thing);
    $maybepenis = end($maybepenis);
    if ($maybepenis == "penis" || $maybepenis == "cactus") {
        return false;
    }
    if ($maybepenis == "cacti") {
        return true;
    }
    if (substr($thing, -1) == "s" && substr($thing, -2) !== "'s") {
        return true;
    }

    return false;
}

function doActionStuff($bat, $chan, $members, $nick, $msg) {
	$matched = false;
	if($bat->checkAttkMatch("(?:attacks|stabs|fites) ([^ ]*)(?: with (.*))?", $msg, $nick)) {
			$result = $bat->doAttacking($bat->attacker, $bat->victim, $bat->weapon);
			/* [0]/["type"] = type of result: normal, fatalNormal, crit, fatalCrit, miss
			 * [1]/["dmg"] = damage done
			 * [2]/["hp"] = victim's new health
			 * [3]/["wep"] = "clean" weapon name */

			// check for fite
			if(!$result['wep']) {
				if(preg_match("/\001ACTION fites (.*)\001/", $msg)) {
					$result['wep'] = "the 1v1 fite irl";
				} else {
					$result['wep'] = "the knife";
				}
			}

			switch($result["type"]) {
				case "miss":
					$lolo = rand(1, 3);
					if($lolo == 1) {
						// miss
						$msg2 = "MISS!";
					} elseif($lolo == 2) {
						$msg2 = "{$bat->victim} is immune to {$result['wep']}";
					} else {
						$msg2 = "\001ACTION calls the police\001";
					}
                                        printf("PRIVMSG %s :%s\r\n", $chan, $msg2);
					$manualsnd = true;
					break;

				case "fatalNormal":
                                        printf("PRIVMSG %s :%s\r\n", $chan, "{$bat->victim} is fatally injured by {$result['wep']}, taking {$result['dmg']} damage. RIP");
					$bat->doRespawn($bat->victim);
					$manualsnd = true;
					break;

				case "fatalCrit":
                                        printf("PRIVMSG %s :%s\r\n", $chan, "{$bat->victim} is \002CRITICALLY HIT\002 to \002DEATH\002 by {$result['wep']}, taking {$result['dmg']} damage! RIP");
					$bat->doRespawn($bat->victim);
					$manualsnd = true;
					break;

				case "normal":
					if($result['dmg'] > 1500) {
						$msg2 = "{$bat->victim} is tremendously damaged by {$result['wep']}, taking {$result['dmg']} damage!";
					} elseif($result['dmg'] < 200) {
						$msg2 = "{$bat->victim} barely even felt {$result['wep']}, taking {$result['dmg']} damage.";
					} else {
						$msg2 = "{$bat->victim} takes {$result['dmg']} damage from {$result['wep']}.";
					}
					$manualsnd = false;
					break;

				case "crit":
					if($result['type'] !== "normal") { // i'm bad
						$msg2 = "{$bat->victim} is \002CRITICALLY HIT\002 by {$result['wep']}, taking {$result['dmg']} damage!";
					}
					$manualsnd = false;
					break;
			}
			$matched = true;
	} elseif($bat->checkAttkMatch("throws (.*) at (.*)", $msg, $nick, true) or $bat->checkAttkMatch("drops (.*) on (.*)", $msg, $nick, true) or $bat->checkAttkMatch("thwacks (.*) with (.*)", $msg, $nick)) {	
			$result = $bat->doAttacking($bat->attacker, $bat->victim, $bat->weapon);

			$result['wep'] = ucfirst($result['wep']);

			if($result['wep'] == "The bass") {
				if(preg_match("/\001ACTION drops (.*) on (.*)\001/", $msg)) {
					$result['wep'] = "The dubstep";
				}
			}

			switch($result['type']) {
				case "miss":
					// hit some other random person in the channel
					$randperson = $members[array_rand($members)];
					$whoitwassupposedtohit = $bat->victim;
					$result = $bat->doAttacking($bat->attacker, $randperson, $bat->weapon, true);
					$msg2 = "{$bat->attacker} missed {$whoitwassupposedtohit} and instead hit {$randperson}, dealing {$result['dmg']} damage!";
					$manualsnd = false;
					break;

				case "fatalNormal":
				case "fatalCrit":
                                        printf("PRIVMSG %s :%s\r\n", $chan, "{$result['wep']} hit {$bat->victim} so hard that {$bat->they_now($bat->victim, 3)} fell over and died, taking {$result['dmg']} damage. RIP");
					$bat->doRespawn($bat->victim);
					$manualsnd = true;
					break;

				case "normal":
				case "crit":
					// check if the weapon is a user in the channel
					if(in_array(substr($result['wep'], 4), $members)) {
						// hurt the weaponised user too
						$userweaponised = true;
						$weaponiseduser = substr($result['wep'], 4);
						// check if they're in game
						if (!$bat->checkPlayerInGame($weaponiseduser)) {
							// attacker isn't in game, add them
							$bat->addPlayer($weaponiseduser);
						}
						$wuhp = $bat->damagePlayer($weaponiseduser, $result['dmg']);
					} else { $userweaponised = false; }

					if($result['dmg'] > 1500) {
						// FUCK THE ENGLISH LANGUAGE
						if(isPlural($result["wep"])) {
							$msg2 = "{$result['wep']} severely injure";
						} else {
							$msg2 = "{$result['wep']} severely injures";
						}

						if($userweaponised) {
							$msg2 = $msg2." {$bat->victim}, dealing {$result['dmg']} damage to both!";
						} else {
							$msg2 = $msg2." {$bat->victim}, dealing {$result['dmg']} damage!";
						}
					} elseif($result['dmg'] < 200) {
						if($userweaponised) {
							$msg2 = "{$result['wep']} barely hit {$bat->victim}, dealing {$result['dmg']} damage to both.";
						} else {
							$msg2 = "{$result['wep']} barely hit {$bat->victim}, dealing {$result['dmg']} damage.";
						}
					} else {
						if(isPlural($result["wep"])) {
							$msg2 = "{$result['wep']} thwack";
						} else {
							$msg2 = "{$result['wep']} thwacks";
						}

						if($userweaponised) {
							$msg2 = $msg2." {$bat->victim} in the face, dealing {$result['dmg']} damage to both.";
						} else {
							$msg2 = $msg2." {$bat->victim} in the face, dealing {$result['dmg']} damage.";
						}
					}
					if($userweaponised) {
						$manualsnd = true;
						$msg2 = $msg2." {$bat->victim} now has {$result['hp']} HP, and {$weaponiseduser} now has {$wuhp} HP.";
                                                printf("PRIVMSG %s :%s\r\n", $chan, $msg2);
					} else {
						$manualsnd = false;
					}
					break;
			}
			$matched = true;
	} elseif($bat->checkAttkMatch("casts (.*) (?:at|on) (.*)", $msg, $nick, true)) {
			$result = $bat->doAttacking($bat->attacker, $bat->victim, $bat->weapon);

			if(!stristr($result['wep'], "'s")) {
				$wep = substr($result['wep'], 4); // remove the because no 's
			} else {
				$wep = $result['wep'];
			}

			switch($result['type']) {
				case "miss":
                                        printf("PRIVMSG %s :%s\r\n", $chan, "You failed at casting...");
					$manualsnd = true;
					break;

				case "fatalNormal":
				case "fatalCrit":
                                        printf("PRIVMSG %s :%s\r\n", $chan, "{$bat->attacker} casts a fatal spell of {$wep} at {$bat->victim}, dealing {$result['dmg']} damage. RIP");
					$bat->doRespawn($bat->victim);
					$manualsnd = true;
					break;

				case "normal":
				case "crit":
					$msg2 = "{$bat->attacker} casts {$wep} at {$bat->victim}, dealing {$result['dmg']} damage.";
					$manualsnd = false;
					break;
			}
			$matched = true;
	} elseif($bat->checkForHealCmd($msg, $nick)) {
		$result = $bat->doHealing($bat->patient, $bat->healer, $bat->tool);
		if ($result["tool"]) {
			$with_tool = " with {$result['tool']}";
			$maim_self = "{$result['tool']} hurt {$bat->healer}";
			$fatal_self = "{$result['tool']} KILLED {$bat->healer}";
		}
		else {
			$with_tool = "";
			$maim_self = "{$bat->healer} hurt themself";
			$fatal_self = "{$bat->healer} KILLED themself";
		}

		if($result['type'] == "fail") {
                        printf("PRIVMSG %s :%s\r\n", $chan, "{$bat->healer} tried to heal {$bat->patient}{$with_tool}, however {$bat->they_now($bat->healer, 3)} failed. :(");
			$manualsnd = true;
		} elseif($result['type'] == "success") {
			$msg2 = "{$bat->healer} managed to heal {$bat->patient} for {$result['healing']} HP{$with_tool}!";
			$manualsnd = false;
		} elseif($result['type'] == "backfire") {
			$msg2 = "In a freak accident, {$maim_self} for {$result['healing']} damage instead of healing {$bat->patient}!";
			$manualsnd = false;
		} elseif($result['type'] == "fatalbackfire") {
                        printf("PRIVMSG %s :%s\r\n", $chan, "In a freak accident, {$fatal_self} with {$result['healing']} damage instead of healing {$bat->patient}!");
			$bat->doRespawn($bat->healer);
			$manualsnd = true;
		}
		$matched = true;
		$bat->victim = $bat->patient;
	}

	if($matched && !$manualsnd) {
		if(!isset($pronoun_has)) {
			$pronoun_has = $bat->they_now($bat->victim, 1);
		}
		$msg2 = $msg2." {$pronoun_has} {$result['hp']} HP.";
                printf("PRIVMSG %s :%s\r\n", $chan, $msg2);
		unset($pronoun_has);
	}
}

$bat = new bdBattle();
while ($line = fgets(STDIN)) {
        $line = explode(" ", rtrim($line, "\n"), 4);
	if (count($line) != 4)
		continue;
	$line[1] = explode(",", $line[1]);
        // chan, members, nick, msg
        doActionStuff($bat, $line[0], $line[1], $line[2], $line[3]);
	fflush($stdout);
}

?>
