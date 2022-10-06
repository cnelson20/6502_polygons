.setcpu "65c02"

.importzp sp, sreg 
.import popa

;
; void __fastcall__ set_vram(unsigned char color, unsigned long bytes);
;
.export _set_vram
_set_vram:
	tay 
	
	lda (sp)

	cpy #0
	beq :++
	:
	sta $9F23
	dey 
	bne :-
	:
	
	inc sreg
	cpx #0
	beq @sreg_count
	dex 
	
@loop_outer:
	ldy #32
@loop_inner:
	sta $9F23
	sta $9F23
	sta $9F23
	sta $9F23
	sta $9F23
	sta $9F23
	sta $9F23
	sta $9F23
	
	dey
	bne @loop_inner
	dex
	bne @loop_outer
@sreg_count:
	dec sreg
	bne @loop_outer

@end:	
	jsr popa
	rts