Stanley Kudzu
=============

Stan is an IRC bot written primarily in awk. His chat module produces Markov
chains when he is highlighted, and he learns from listening to the channels he
is in (``LEARN_CHANS``, subject to ``IGNORE`` and ``IGNOREPAT``).

User commands
--------------

``%add quote text``
	Adds a quote to the quote database. See also the ``QUOTE_FILE``
	configuration option.

``%grab [nick]``
	Grabs the last line from the given nickname and adds it to the quote
	database, or grabs the last line anyone said in the channel if none is
	given.

``%more``
  Continue speaking if the last message was too long.

``%rand [search terms]``
	Searches the quote database case-insenitively using the given search
	terms, or returns a completely random quote.

``%status``
	Describes the current AWK process's uptime as well as the number of
	messages processed.

``%uno [#channel]``
	Attempts to join an UNO game on the given channel or the current
	channel if none is given. See also the ``UNO_MASTER`` configuration
	option.

``%uptime``
	Returns the output of ``uptime(1)``.

Administrative commands
-----------------------

These commands can only be run by the user who matches the ``OWNERMASK``
configuration option.

``%chat``
	Enables chat functionality on the given channel. See also the
	``CHAT_CHANS`` configuration option.

``%identify``
	Send configured password (``NS_PASSWORD``) to NickServ.

``%join #channel``
	Join the specified channel.

``%nick new_nick``
	Change nickname.

``%part #channel``
	Leave the specified channel.

``%quiet``
	Disables chat functionality on the given channel. See also the
	``CHAT_CHANS`` configuration option.

``%quit``
	Disconnect from the network.

``%restart``
	Restart the bot's AWK process. Note that the connection should remain
	open.

``%say #channel message``
	Send a message to a particular channel or user.

``%sync``
	Resets the list of currently active channels and the users in each
	one.

Acknowledgements
----------------
* `Fun with Markov Chains
  <http://petermblair.com/2013/06/fun-with-markov-chains/>`_. Peter
  Blair, June 20, 2013.
