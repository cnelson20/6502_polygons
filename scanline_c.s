.SETCPU "65c02"
	
.macro movwrd dest, src
	lda src
	sta dest
	lda src+1
	sta dest+1
.endmacro

.macro round addr
	lda addr
	cmp #128
	lda #0
	adc addr+1
.endmacro


; 
; 'Borrowed' from online site
; 
.macro divide16 num1, num2, rem
	LDA #0      ;Initialize REM to 0
	STA rem
	STA rem+1
	LDX #16     ;There are 16 bits in NUM1
:      
	ASL num1    ;Shift hi bit of NUM1 into REM
	ROL num1+1  ;(vacating the lo bit, which will be used for the quotient)
	ROL rem
	ROL rem+1
	LDA rem
	SEC         ;Trial subtraction
	SBC num2
	TAY
	LDA rem+1
	SBC num2+1
	BCC :+      ;Did subtraction succeed?
	STA rem+1   ;If yes, save it
	STY rem
	INC num1    ;and record a 1 in the quotient
:
	DEX
	BNE :--
.endmacro


.export _draw_polygon_addr
_draw_polygon_addr:
	.word 0
	
.export _draw_polygon_color	
_draw_polygon_color:
	.byte 0
	
.export _draw_polygon_top_x
_draw_polygon_top_x:
	.word 0
	
.export _draw_polygon_top_y
_draw_polygon_top_y:
	.word 0
	
.export _draw_polygon_middle_x
_draw_polygon_middle_x:
	.word 0
	
.export _draw_polygon_middle_y
_draw_polygon_middle_y:
	.word 0
	
.export _draw_polygon_bottom_x
_draw_polygon_bottom_x:
	.word 0
	
.export _draw_polygon_bottom_y
_draw_polygon_bottom_y:
	.word 0
	
.export _draw_polygon
_draw_polygon:
	jmp @func_start
@ymin:
	.byte 0
@midy:
	.byte 0
@ymax:
	.byte 0
@x0:
	.word 0
@x1:
	.word 0
@dx0:
	.word 0
@dx0_direction:
	.byte 0
@dx1:
	.word 0
@dx1_direction:
	.byte 0
@dx1_1:
	.word 0
@dx1_1_direction:
	.byte 0
@y_curr:
	.byte 0

@divisor_temp:
	.word 0
@remainder_temp:
	.word 0
	
@func_start:
	movwrd @x0, _draw_polygon_top_x
	movwrd @x1, _draw_polygon_top_x
	
	round _draw_polygon_bottom_y
	sta @ymax
	round _draw_polygon_middle_y
	sta @midy
	round _draw_polygon_top_y
	sta @y_curr
	sta @ymin
	
	
	; Calculate dx0
	lda _draw_polygon_bottom_x + 1
	cmp _draw_polygon_top_x + 1
	bcc :++
	bne :+
	lda _draw_polygon_bottom_x
	cmp _draw_polygon_top_x
	bcc :++
	
	:	
	;positive
	sec
	lda _draw_polygon_bottom_x
	sbc _draw_polygon_top_x
	sta @dx0
	lda _draw_polygon_bottom_x + 1
	sbc _draw_polygon_top_x + 1
	sta @dx0 + 1
	
	
	lda #1
	sta @dx0_direction
	jmp :++
	:
	; negative
	sec
	lda _draw_polygon_top_x
	sbc _draw_polygon_bottom_x
	sta @dx0
	lda _draw_polygon_top_x + 1
	sbc _draw_polygon_bottom_x + 1
	sta @dx0 + 1
	
	lda #0
	sta @dx0_direction
	:
	
	sec
	lda @ymax
	sbc @ymin
	sta @divisor_temp
	lda #0
	sta @divisor_temp + 1
	
	divide16 @dx0, @divisor_temp, @remainder_temp
	
	;
	; Calculate dx1_1
	;
	lda @midy
	cmp @ymax
	bne :+
	jmp @midy_equals_ymax
	:
	
	
	lda _draw_polygon_bottom_x + 1
	cmp _draw_polygon_middle_x + 1
	bcc :++
	bne :+
	lda _draw_polygon_bottom_x
	cmp _draw_polygon_middle_x
	bcc :++
	
	:
	;positive
	sec
	lda _draw_polygon_bottom_x
	sbc _draw_polygon_middle_x
	sta @dx1_1
	lda _draw_polygon_bottom_x + 1
	sbc _draw_polygon_middle_x + 1
	sta @dx1_1 + 1
	
	
	lda #1
	sta @dx1_1_direction
	jmp :++
	:
	; negative
	sec
	lda _draw_polygon_middle_x
	sbc _draw_polygon_bottom_x
	sta @dx1_1
	lda _draw_polygon_middle_x + 1
	sbc _draw_polygon_bottom_x + 1
	sta @dx1_1 + 1
	
	lda #0
	sta @dx1_1_direction
	:
	
	sec
	lda @ymax
	sbc @midy
	sta @divisor_temp
	lda #0
	sta @divisor_temp + 1
	
	divide16 @dx1_1, @divisor_temp, @remainder_temp
	
	
	@midy_equals_ymax:
	
	;
	; Calculate dx1 
	;
	lda @ymin
	cmp @midy
	bne :+
	
	movwrd @x1, _draw_polygon_middle_x
	movwrd @dx1, @dx1_1
	lda @dx1_1_direction
	sta @dx1_direction
	
	jmp @end_dx1_calc
	: ; Actually calc dx1 now
	
	lda _draw_polygon_middle_x + 1
	cmp _draw_polygon_top_x + 1
	bcc :++
	bne :+
	lda _draw_polygon_middle_x
	cmp _draw_polygon_top_x
	bcc :++
	
	:	
	;positive
	sec
	lda _draw_polygon_middle_x
	sbc _draw_polygon_top_x
	sta @dx1
	lda _draw_polygon_middle_x + 1
	sbc _draw_polygon_top_x + 1
	sta @dx1 + 1
	
	
	lda #1
	sta @dx1_direction
	jmp :++
	:
	; negative
	sec
	lda _draw_polygon_top_x
	sbc _draw_polygon_middle_x
	sta @dx1
	lda _draw_polygon_top_x + 1
	sbc _draw_polygon_middle_x + 1
	sta @dx1 + 1
	
	lda #0
	sta @dx1_direction
	:
	
	sec
	lda @midy
	sbc @ymin
	sta @divisor_temp
	lda #0
	sta @divisor_temp + 1
	
	divide16 @dx1, @divisor_temp, @remainder_temp
	
	; End of calculation
	@end_dx1_calc:
	
;
; Main Loop
;	
@loop:
	;lda @y_curr
	;jsr print_hex
	;lda #$20
	;jsr $FFD2
	;printword @x0
	;printword @x1
	;lda #$0D
	;jsr $FFD2

	lda @y_curr
	cmp @ymax
	bcc :+
	jmp @func_end
	:
	
	round @x0
	tax
	round @x1
	tay
	lda @y_curr
	jsr draw_horiz
	
	;
	; Add / Subtract dx0 to / from x0 ;
	;
	lda @dx0_direction
	beq :+
	; add dx0 to x0
	
	clc
	lda @x0
	adc @dx0
	sta @x0
	lda @x0 + 1
	adc @dx0 + 1
	sta @x0 + 1	
	
	jmp :++
	: ; subtract dx0 from x0
	
	sec
	lda @x0
	sbc @dx0 
	sta @x0
	lda @x0 + 1
	sbc @dx0 + 1
	sta @x0 + 1	
	:
	
	;
	; Add / Subtract dx1 to / from x1 ;
	;
	lda @dx1_direction
	beq :+
	; add dx1 to x1	
	
	clc
	lda @x1
	adc @dx1
	sta @x1
	lda @x1 + 1
	adc @dx1 + 1
	sta @x1 + 1	
	
	jmp :++
	: ; subtract dx1 from x1
	
	sec
	lda @x1
	sbc @dx1
	sta @x1
	lda @x1 + 1
	sbc @dx1 + 1
	sta @x1 + 1	
	
	:
	
	ldx @y_curr
	inx
	stx @y_curr
	cpx @midy
	;bne @loop_finish
	beq :+
	jmp @loop_finish
	:
	
	cpx @ymax
	bne :+
	
	round @x0
	tax
	round @x1
	tay
	lda @y_curr
	jsr draw_horiz
	jmp @func_end ; exit loop
	
	:
	
	movwrd @dx1, @dx1_1
	movwrd @x1, _draw_polygon_middle_x
	lda @dx1_1_direction
	sta @dx1_direction
	
@loop_finish:
	jmp @loop
@func_end:
	rts 
	
draw_horiz:
	sta @f_y
	sty @f_x1
	cpx @f_x1
	bcc :+
	beq :+
	
	txa
	tay
	ldx @f_x1
	lda @f_y
	jmp draw_horiz
	
	:
	stx @f_x0
	
	lda @f_x1
	cmp #64
	bcc :+
	lda #63
	sta @f_x1
	:
	
	lda #$11
	sta $9F22

	lda @f_y
	lsr 
	lsr 
	clc 
	adc _draw_polygon_addr+1
	sta $9F21
	
	lda @f_y
	asl
	asl 
	asl 
	asl 
	asl
	asl
	clc 
	adc @f_x0

	sta $9F20


	ldy @f_x0
	lda _draw_polygon_color
@loop:
	sta $9F23

	iny 
	cpy @f_x1
	bcs @end
	bra @loop
@end:
	rts
@f_y:
	.byte 0
@f_x0:
	.byte 0
@f_x1:
	.byte 0


.importzp sp 
.import popa

.export _set_vram
_set_vram:
	tay 

	lda (sp)

	:
	sta $9F23
	dey
	bne :-
	dex
	bne :-

	jsr popa
	rts