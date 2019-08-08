      * vi: ts=4 sts=4 sw=4 et
           MOVE option TO config-opt-TXT
           START config-FC
               KEY IS EQUAL TO config-opt-TXT
               INVALID KEY
                   missing
               NOT INVALID KEY
                   READ config-FC NEXT RECORD
                   PERFORM
                       UNTIL TRIM(config-opt-TXT)
                           IS GREATER THAN option

                       available

                       READ config-FC NEXT RECORD
                           AT END
                               EXIT PERFORM
                       END-READ
                   END-PERFORM
           END-START
