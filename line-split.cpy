      * vi: ts=4 sts=4 sw=4 et
           MOVE line-IDX TO id0
           MOVE line-IDX TO id1
           UNSTRING line-TXT
               DELIMITED BY DELIMS
      *        We have to store something to use UNSTRING, so
      *        just store a single character. This variable is otherwise
      *        unused.
               INTO CHR
               DELIMSAVE
               WITH POINTER id1
           END-UNSTRING
      *    Advance position in line-TXT when we continue processing.
           MOVE id1 TO line-IDX
      *    Remove delimiter and the character after it.
           SUBTRACT 2 FROM id1
