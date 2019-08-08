      * vi: ts=4 sts=4 sw=4 et
           MOVE option TO config-opt-TXT
           READ config-FC RECORD
               KEY IS config-opt-TXT
               INVALID KEY
                   MOVE default TO config-val-TXT
           END-READ
