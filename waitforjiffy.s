RDTIM = $FFDE

.export _waitforjiffy
_waitforjiffy:

jsr RDTIM
sta @byte
:
jsr RDTIM
cmp @byte
beq :-

rts

@byte:
	.byte 0