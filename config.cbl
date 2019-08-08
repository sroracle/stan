      * vi: ts=4 sts=4 sw=4 et
       IDENTIFICATION DIVISION.
       PROGRAM-ID. stan-cfg.

      *****************************************************************

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION TRIM INTRINSIC.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SYSIN
               ASSIGN TO KEYBOARD
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT config-FC
               ASSIGN TO DISK "stan.cfg"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS RANDOM
               RECORD KEY IS config-IDX
               ALTERNATE RECORD KEY IS config-opt-TXT WITH DUPLICATES.

      *****************************************************************

       DATA DIVISION.
       FILE SECTION.
       FD SYSIN.
       01 FILLER.
           05 input-opt-TXT
               PICTURE IS X(15).
           05 input-val-TXT
               PICTURE IS X(65).

       FD config-FC.
       01 config-REC.
           05 config-IDX
               USAGE IS INDEX
               VALUE IS 1.
           05 config-opt-TXT
               PICTURE IS X(15).
           05 config-val-TXT
               PICTURE IS X(65).

       WORKING-STORAGE SECTION.

       01 IDX
           USAGE IS INDEX
           VALUE IS 1.

      *****************************************************************

       PROCEDURE DIVISION.

           OPEN INPUT SYSIN
           OPEN OUTPUT config-FC

           PERFORM
               UNTIL EXIT
               READ SYSIN
                   AT END EXIT PERFORM
               END-READ

               MOVE IDX to config-IDX
               MOVE input-opt-TXT TO config-opt-TXT
               MOVE input-val-TXT TO config-val-TXT

               WRITE config-REC

               ADD 1 TO IDX
           END-PERFORM

           CLOSE SYSIN
           CLOSE config-FC
           STOP RUN

           .

       END PROGRAM stan-cfg.
