      * vi: ts=4 sts=4 sw=4 et
      * cobc -fixed -x
      * add -fdebugging-line for D lines
       IDENTIFICATION DIVISION.
       PROGRAM-ID. stan.

      *****************************************************************

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION TRIM INTRINSIC
           FUNCTION WHEN-COMPILED INTRINSIC.
       SPECIAL-NAMES.
           SYMBOLIC CHARACTERS
      * Note that SYMBOLIC CHARACTERS are specified by their ordinal
      * position, not their value. Thus carriage return is ordinal 14
      * instead of decimal 013 / hexadecimal 0x00D / octal 015.
               CR IS 14.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SYSIN
               ASSIGN TO KEYBOARD
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT config-FC
               ASSIGN TO DISK "stan.cfg"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS config-IDX
               ALTERNATE RECORD KEY IS config-opt-TXT WITH DUPLICATES.

      *****************************************************************

      * * * * * * * * * * * * * * * * * * * *
      * Files.                              *
      * * * * * * * * * * * * * * * * * * * *
       DATA DIVISION.
       FILE SECTION.
       FD SYSIN.
       01 line-TXT
           PICTURE IS X(512).

       FD config-FC.
       01 FILLER.
      *    This isn't ever used directly - just need to fulfill the
      *    requirement of having some unique key.
           05 config-IDX
               USAGE IS INDEX.
      *    Instead, we search by the alternate key, which may or may not
      *    have duplicates. This is useful for e.g. defining multiple
      *    nicks to ignore.
           05 config-opt-TXT
               PICTURE IS X(15).
           05 config-val-TXT
               PICTURE IS X(65).

       WORKING-STORAGE SECTION.

      * * * * * * * * * * * * * * * * * * * *
      * Configuration defaults.             *
      * * * * * * * * * * * * * * * * * * * *
       78 default-nick-TXT
           VALUE IS "Stan".

       78 default-cmd-prefix-CHR
           VALUE IS "%".

       78 default-user-TXT
           VALUE IS "stan".

       78 default-realname-TXT
           VALUE IS "Stanley Kudzu".

      * * * * * * * * * * * * * * * * * * * *
      * Program state.                      *
      * * * * * * * * * * * * * * * * * * * *
       01 my-nick-TXT
           PICTURE IS X(65).

       01 my-cmd-prefix-CHR
           PICTURE IS X.

       01 police-CHR
           PICTURE IS 9
           VALUE IS 0.

      * * * * * * * * * * * * * * * * * * * *
      * Line state.                         *
      * * * * * * * * * * * * * * * * * * * *
       01 line-IDX
           USAGE IS INDEX.

       01 ignore-NUM
           PICTURE IS 9.

       01 reply-TXT
           PICTURE IS X(512).

      * * * * * * * * * * * * * * * * * * * *
      * Constants.                          *
      * * * * * * * * * * * * * * * * * * * *
       01 zero-IDXs.
           05 FILLER OCCURS 2 TIMES
               USAGE IS INDEX
               VALUE IS 0.

       01 msg-status-values.
      *                 01234567890
           05 FILLER
               VALUE IS "<<< ".
           05 FILLER
               VALUE IS "~~~ ".
           05 FILLER
               VALUE IS "... ".

       01 FILLER REDEFINES msg-status-values.
           05 msg-status-TBL OCCURS 3 TIMES
               PICTURE IS X(4).

       01 police-values.
      *                 012345678901234567890
           05 FILLER
               VALUE IS "POLICE:OFF         ".
           05 FILLER
               VALUE IS "POLICE:ON          ".
           05 FILLER
               VALUE IS "POLICE:ON_FULLPOWER".

       01 FILLER REDEFINES police-values.
           05 police-TBL OCCURS 3 TIMES
               PICTURE IS X(19).

      * * * * * * * * * * * * * * * * * * * *
      * Line components.                    *
      * * * * * * * * * * * * * * * * * * * *
       01 CHR
           PICTURE IS X.

       REPLACE ALSO ==nick-TXT==
           BY ==line-TXT(nick0 : nick1 - nick0 + 1)==.
       01 nick.
           05 nick0
               USAGE IS INDEX.
           05 nick1
               USAGE IS INDEX.
           05 bang-CHR
               PICTURE IS X.
           88 is-user-BOOL
               VALUE IS "!".
           88 is-server-BOOL
               VALUE IS " ".
       REPLACE ALSO ==user-TXT==
           BY ==line-TXT(user0 : user1 - user0 + 1)==.
       01 user.
           05 user0
               USAGE IS INDEX.
           05 user1
               USAGE IS INDEX.
       REPLACE ALSO ==host-TXT==
           BY ==line-TXT(host0 : host1 - host0 + 1)==.
       01 host.
           05 host0
               USAGE IS INDEX.
           05 host1
               USAGE IS INDEX.
       REPLACE ALSO ==hostmask-TXT==
           BY ==line-TXT(hostmask0 : hostmask1 - hostmask0 + 1)==.
       01 hostmask.
           05 hostmask0
               USAGE IS INDEX.
           05 hostmask1
               USAGE IS INDEX.
       REPLACE ALSO ==category-TXT==
           BY ==line-TXT(category0 : category1 - category0 + 1)==.
       01 category.
           05 category0
               USAGE IS INDEX.
           05 category1
               USAGE IS INDEX.
       REPLACE ALSO ==chan-TXT==
           BY ==line-TXT(chan0 : chan1 - chan0 + 1)==.
       01 chan.
           05 chan0
               USAGE IS INDEX.
           05 chan1
               USAGE IS INDEX.
       REPLACE ALSO ==msg-TXT==
           BY ==TRIM(line-TXT(msg0 : ))==.
       01 msg.
           05 msg0
               USAGE IS INDEX.
       REPLACE ALSO ==cmd-TXT==
           BY ==line-TXT(cmd0 : cmd1 - cmd0 + 1)==.
       01 cmd.
           05 cmd0
               USAGE IS INDEX.
           05 cmd1
               USAGE IS INDEX.

      *****************************************************************

       PROCEDURE DIVISION.
       000-main SECTION.

           DISPLAY "Program compiled on " WHEN-COMPILED "." UPON SYSERR

           OPEN INPUT config-FC
           OPEN INPUT SYSIN

           PERFORM 001-init-state
           PERFORM 200-start-connection

           PERFORM
               UNTIL EXIT
               READ SYSIN
                   AT END EXIT PERFORM
               END-READ

               PERFORM 100-process-line

               IF nick-TXT IS EQUAL TO "PING" THEN
                   PERFORM 205-pingpong
                   EXIT PERFORM CYCLE
               END-IF

               EVALUATE category-TXT
                   WHEN "001"
      *                Welcome message - usually safe to join now
                       PERFORM 210-finish-connection
                   WHEN "PRIVMSG"
                       PERFORM 220-process-privmsg
                   WHEN "NOTICE"
                       MOVE 2 TO ignore-NUM
                       PERFORM 220-process-privmsg
               END-EVALUATE
           END-PERFORM

           CLOSE SYSIN
           CLOSE config-FC
           STOP RUN

           .

      * * * * * * * * * * * * * * * * * * * *

       001-init-state SECTION.

           COPY "config-simple.cpy" REPLACING
               option BY "prefix"
               default BY default-cmd-prefix-CHR.
           MOVE config-val-TXT TO my-cmd-prefix-CHR

           COPY "config-simple.cpy" REPLACING
               option BY "nick"
               default BY default-nick-TXT.
           MOVE config-val-TXT TO my-nick-TXT

           .

      * * * * * * * * * * * * * * * * * * * *

       010-ltrim-colon SECTION.

           PERFORM
               UNTIL line-TXT(line-IDX : 1) IS NOT EQUAL TO ":"
               ADD 1 TO line-IDX
           END-PERFORM

           .

      * * * * * * * * * * * * * * * * * * * *

       100-process-line SECTION.

           MOVE 1 TO line-IDX
           MOVE 0 TO ignore-NUM
           MOVE CORRESPONDING zero-IDXs TO nick
           MOVE CORRESPONDING zero-IDXs TO user
           MOVE CORRESPONDING zero-IDXs TO host
           MOVE CORRESPONDING zero-IDXs TO category
           MOVE SPACE TO reply-TXT

           PERFORM 010-ltrim-colon
           PERFORM 110-process-nick

           IF is-user-BOOL THEN
               PERFORM 120-process-user
               PERFORM 130-process-host

               MOVE nick0 TO hostmask0
               MOVE host1 TO hostmask1
           ELSE
               MOVE nick0 TO hostmask0
               MOVE nick1 TO hostmask1
           END-IF

           PERFORM 140-process-category
           PERFORM 101-debug-line

           .

      * * * * * * * * * * * * * * * * * * * *

       101-debug-line SECTION.

      *    Put a no-op here in case the debug lines are elided
           CONTINUE

      D    DISPLAY "hostmask0=" hostmask0 UPON SYSERR
      D    DISPLAY "hostmask1=" hostmask1 UPON SYSERR
      D    DISPLAY "hostmask-TXT=" hostmask-TXT UPON SYSERR
      D    DISPLAY "nick0=" nick0 UPON SYSERR
      D    DISPLAY "nick1=" nick1 UPON SYSERR
      D    DISPLAY "nick-TXT=" nick-TXT UPON SYSERR
      D    DISPLAY "user0=" user0 UPON SYSERR
      D    DISPLAY "user1=" user1 UPON SYSERR
      D    DISPLAY "user-TXT=" user-TXT UPON SYSERR
      D    DISPLAY "host0=" host0 UPON SYSERR
      D    DISPLAY "host1=" host1 UPON SYSERR
      D    DISPLAY "host-TXT=" host-TXT UPON SYSERR
      D    DISPLAY "category0=" category0 UPON SYSERR
      D    DISPLAY "category1=" category1 UPON SYSERR
      D    DISPLAY "category-TXT=" category-TXT UPON SYSERR

           .

      * * * * * * * * * * * * * * * * * * * *

       110-process-nick SECTION.

           COPY "line-split.cpy" REPLACING
               LEADING ==id== BY ==nick==
               DELIMS BY =="!" OR " "==
      *        Store "!" or " " to determine later if the sender is
      *        a user or a server.
               DELIMSAVE BY ==DELIMITER IN bang-CHR==.

           .

      * * * * * * * * * * * * * * * * * * * *

       120-process-user SECTION.

           COPY "line-split.cpy" REPLACING
               LEADING ==id== BY ==user==
               DELIMS BY =="@"==
               DELIMSAVE BY ====.

           .

      * * * * * * * * * * * * * * * * * * * *

       130-process-host SECTION.

           COPY "line-split.cpy" REPLACING
               LEADING ==id== BY ==host==
               DELIMS BY ==" "==
               DELIMSAVE BY ====.

           .

      * * * * * * * * * * * * * * * * * * * *

       140-process-category SECTION.

           COPY "line-split.cpy" REPLACING
               LEADING ==id== BY ==category==
               DELIMS BY ==" "==
               DELIMSAVE BY ====.

           .

      * * * * * * * * * * * * * * * * * * * *

       200-start-connection SECTION.

           DISPLAY "NICK " TRIM(my-nick-TXT) CR

           COPY "config-simple.cpy" REPLACING
               option BY "user"
               default BY default-user-TXT.
           DISPLAY "USER " TRIM(config-val-TXT) " * * :"
               WITH NO ADVANCING

           COPY "config-simple.cpy" REPLACING
               option BY "realname"
               default BY default-realname-TXT.
           DISPLAY TRIM(config-val-TXT) CR

           .

      * * * * * * * * * * * * * * * * * * * *

       205-pingpong SECTION.

      D        DISPLAY "<<< Ping!" UPON SYSERR

               STRING
                   "PONG " category-TXT
                   INTO reply-TXT
               END-STRING

               DISPLAY TRIM(reply-TXT) CR
      D        DISPLAY ">>> Pong!" UPON SYSERR

           .

      * * * * * * * * * * * * * * * * * * * *

       210-finish-connection SECTION.

           DISPLAY "*** Connected!" UPON SYSERR

           COPY "config.cpy" REPLACING
               option BY "password"
               missing BY CONTINUE
               available BY ==
                   DISPLAY "PRIVMSG NickServ identify "
                   TRIM(config-val-TXT) CR
               ==.

           COPY "config-multiple.cpy" REPLACING
               option BY "channel"
               missing BY CONTINUE
               available BY ==
                   DISPLAY "JOIN " TRIM(config-val-TXT) CR
               ==.

           .

      * * * * * * * * * * * * * * * * * * * *

       220-process-privmsg SECTION.

           COPY "line-split.cpy" REPLACING
               LEADING ==id== BY ==chan==
               DELIMS BY ==" "==
               DELIMSAVE BY ====.
           PERFORM 010-ltrim-colon
           MOVE line-IDX TO msg0

           COPY "config-multiple.cpy" REPLACING
               option BY "ignore"
               missing BY CONTINUE
               available BY ==
                   IF ignore-NUM IS NOT EQUAL TO 0 THEN
                       EXIT PERFORM
                   END-IF
      *            We can't check nick-TXT here directly since it's a
      *            REPLACEment and will not be visible inside the
      *            copybook. So just move the comparison into a separate
      *            procedure.
                   PERFORM 221-check-ignore
                   IF ignore-NUM IS EQUAL TO 1 THEN
                       EXIT PERFORM
                   END-IF
               ==.

           PERFORM 222-display-privmsg

           IF ignore-NUM IS NOT EQUAL TO 0 THEN
               EXIT PARAGRAPH
           END-IF

           IF msg-TXT(1 : 1) IS EQUAL TO my-cmd-prefix-CHR THEN
               PERFORM 300-process-cmd
           END-IF

           .

      * * * * * * * * * * * * * * * * * * * *

       221-check-ignore SECTION.

           IF nick-TXT IS EQUAL TO TRIM(config-val-TXT) THEN
               MOVE 1 TO ignore-NUM
           END-IF

           .

      * * * * * * * * * * * * * * * * * * * *

       222-display-privmsg SECTION.

           DISPLAY msg-status-TBL(ignore-NUM + 1)
               UPON SYSERR WITH NO ADVANCING

           IF chan-TXT IS NOT EQUAL TO TRIM(my-nick-TXT) THEN
               DISPLAY "[" chan-TXT "] " UPON SYSERR WITH NO ADVANCING
           END-IF

           DISPLAY "<" nick-TXT "> " msg-TXT UPON SYSERR

           .

      * * * * * * * * * * * * * * * * * * * *

       230-reply-privmsg SECTION.


           IF chan-TXT IS EQUAL TO TRIM(my-nick-TXT) THEN
               DISPLAY ">>> [" nick-TXT "] <" TRIM(my-nick-TXT) "> "
                   TRIM(reply-TXT) UPON SYSERR
               DISPLAY "PRIVMSG " nick-TXT " :" TRIM(reply-TXT) CR
           ELSE
               DISPLAY ">>> [" chan-TXT "] <" TRIM(my-nick-TXT) "> "
                   TRIM(reply-TXT) UPON SYSERR
               DISPLAY "PRIVMSG " chan-TXT " :" TRIM(reply-TXT) CR
           END-IF

           .

      * * * * * * * * * * * * * * * * * * * *

       300-process-cmd SECTION.

           ADD 1 TO line-IDX
           COPY "line-split.cpy" REPLACING
               LEADING ==id== BY ==cmd==
               DELIMS BY ==" "==
               DELIMSAVE BY ====.

           EVALUATE cmd-TXT
               WHEN "test"
                   MOVE "Ok" TO reply-TXT
                   PERFORM 230-reply-privmsg
               WHEN "police"
                   PERFORM 301-police
               WHEN "nsa"
                   PERFORM 302-nsa
               WHEN "cocain"
                   PERFORM 303-cocain
               WHEN "status"
                   PERFORM 304-status
           END-EVALUATE

           .

      * * * * * * * * * * * * * * * * * * * *

       301-police SECTION.

           COPY "line-split.cpy" REPLACING
               LEADING ==id== BY ==cmd==
               DELIMS BY ==" "==
               DELIMSAVE BY ====.

           EVALUATE cmd-TXT
               WHEN "OFF"
                   MOVE 0 TO police-CHR
               WHEN "ON"
                   MOVE 1 TO police-CHR
               WHEN "ON_FULLPOWER"
                   MOVE 2 TO police-CHR
               WHEN SPACE
                   CONTINUE
               WHEN OTHER
                   MOVE "Huh?" TO reply-TXT
                   PERFORM 230-reply-privmsg
                   EXIT PARAGRAPH
           END-EVALUATE

           MOVE police-TBL(police-CHR + 1) TO reply-TXT
           PERFORM 230-reply-privmsg

           .

      * * * * * * * * * * * * * * * * * * * *

       302-nsa SECTION.

           MOVE "Do skype,yahoo other chat and social communication prog
      -        " work 2 spoil muslims youth and spy 4 isreal&usa???????"
               TO reply-TXT
           PERFORM 230-reply-privmsg

           MOVE "do they record and analyse every word we type??????????
      -        "??"
               TO reply-TXT
           PERFORM 230-reply-privmsg

           .

      * * * * * * * * * * * * * * * * * * * *

       303-cocain SECTION.

           COPY "line-split.cpy" REPLACING
               LEADING ==id== BY ==cmd==
               DELIMS BY ==" "==
               DELIMSAVE BY ====.

           IF cmd-TXT IS EQUAL TO SPACE THEN
               MOVE "Who?" TO reply-TXT
           ELSE
               STRING
                   "i fucking hate "
                   cmd-TXT
                   ". i bet they cnt evil lift many miligram of cocain "
                   "with penis"
                   INTO reply-TXT
               END-STRING
           END-IF

           PERFORM 230-reply-privmsg

           .

      * * * * * * * * * * * * * * * * * * * *

       304-status SECTION.

           STRING
               "Compiled on: "
               WHEN-COMPILED
               INTO reply-TXT
           END-STRING

           PERFORM 230-reply-privmsg

           .

       END PROGRAM stan.
