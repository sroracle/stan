Stanley Kudzu
=============

Stan is an IRC bot written primarily in bash 4. He supports bash and python
modules. His chat module produces markov chains when he is highlighted, and
he learns from listening to the channels he is in.

Basic commands
--------------

* `.calc`: Calculate argument using the [Frink calculator](http://futureboy.us/frinkdocs/). The Frink calculator can perform a myriad of calculations, mathematical and not, including:
 * Basic arithmetic
 * Translation
 * Unit conversion
 * and more
* `.dc`: Calculate using [dc(1), the desktop calculator](http://man.cx/dc)
* `.ping`: [ping(8)](http://man.cx/ping) with -c 4
* `.host`: [host(1)](http://man.cx/host)
* `.weather`: Retrieve weather information for the area provided.
* `.help`: Link to this page
* `.up` or `.uptime`: Display uptime in minutes
* `.sleep`: Sleep for 5 minutes
* `.wake`: Wake up
* `.ver` or `.version`

\#sporks commands
----------------
* `.cocain`
* `.nsa`
* `.police`

Administrative commands
-----------------------
* `.join`
* `.part`
* `.quit`
* `.reload`
* `.let`
 * `.let floodtime=0` disables flood protection

Traps
-----
* `SIGHUP`: reload configuration
* `SIGINT` or `SIGTERM`: close connection and exit

Acknowledgements
----------------
* [contrib/markov.py](contrib/markov.py) and [contrib/split.pl](contrib/split.pl)
  * ["Fun with Markov Chains"](http://petermblair.com/2013/06/fun-with-markov-chains/). Peter Blair, June 20, 2013.
