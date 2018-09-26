; This code attempts to remove an entry from the partition
; table. The entry will be zeroed out.
;
; Written by: Someone from COMP6845
;

[bits 16]
[org 0x0600]

_start:
    cli
    
