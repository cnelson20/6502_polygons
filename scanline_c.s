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
	lda addr+1
	adc #0	
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
	

.importzp tmp1, tmp2, tmp3, tmp4, ptr1, ptr2, ptr3, ptr4
.importzp regsave, sreg

;
; void draw_polygon();
;	
.export _draw_polygon
_draw_polygon:
	jmp @func_start
@ymin:
	.byte 0
@midy:
	.byte 0
@ymax:
	.byte 0
@x0 = ptr4
@x1 = sreg

@dx0 = ptr1
@dx0_direction = tmp1
@dx1 = ptr2
@dx1_direction = tmp2
@dx1_1 = ptr3
@dx1_1_direction = tmp3
	.byte 0
@y_curr = regsave

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
	
	stz draw_horiz_setup
	
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
	;  y_curr == ymax
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

draw_horiz_setup := $05
	;.byte 0
horiz_y_addr := $06
	;.res 3, 0
	
.import _waitforjiffy	
	
draw_horiz:
@f_y := $02
@f_x0 := $03
@f_x1 := $04
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
	
	lda draw_horiz_setup
	beq :+	
	
	lda horiz_y_addr
	sta $9F20 
	adc #<320
	sta horiz_y_addr
	lda horiz_y_addr + 1
	sta $9F21
	adc #>320
	sta horiz_y_addr + 1
	lda horiz_y_addr + 2
	sta $9F22
	adc #0
	sta horiz_y_addr + 2
	
	bra @draw_line
	:
	
	stz $9F20 
	stz $9F21
	lda #$E0
	sta draw_horiz_setup ; now will be setup
	sta $9F22
	ldy @f_y
	beq :++
	:
	lda $9F23	
	dey 
	bne :-
	:
@increment_vera_ptr:
	; increment one more time ;
	lda $9F23 ; add 320 more ;
	
	lda $9F20 
	sta horiz_y_addr
	lda $9F21
	sta horiz_y_addr + 1
	lda $9F22 
	and #1
	sta horiz_y_addr + 2
	
	;and #1
	ora #$E8
	sta $9F22
	lda $9F23 ; decrease back to right value
	
@draw_line:	
	lda $9F20
	adc @f_x0
	sta $9F20
	lda $9F21 
	adc #0
	sta $9F21
	lda $9F22
	adc #0
	and #1
	ora #$10
	sta $9F22
	
	; TODO : Use Duff's device
	; to speed up execution of loop
	lda @f_x1
	sec
	sbc @f_x0
	beq @end
	tay
	and #%111
	asl
	tax
	
	tya
	lsr
	lsr 
	lsr
	inc A
	
	ldy _draw_polygon_color
	jmp (@dufftable, X)
@loop:
	sty $9F23
@jt7:
	sty $9F23
@jt6:
	sty $9F23
@jt5:
	sty $9F23
@jt4:
	sty $9F23
@jt3:
	sty $9F23
@jt2:
	sty $9F23
@jt1:
	sty $9F23
@jt0:
	dec A
	bne @loop
@end:
	rts
@dufftable:
	.word @jt0, @jt1, @jt2, @jt3, @jt4, @jt5, @jt6, @jt7