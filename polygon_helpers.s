.setcpu "65c02"

.macro movwrd dest, src
	lda src
	sta dest
	lda src+1
	sta dest+1
.endmacro

.macro movconst dest, val
	lda #<val
	sta dest
	lda #>val
	sta dest+1
.endmacro


.struct dyn_array_short
	array .word
	space_allocated .word
	length .word
.endstruct

.struct signed_short
	val .word
	sign .byte
	color_buffer .byte
.endstruct

.importzp ptr1, ptr2, ptr3
.importzp tmp1, tmp2, tmp3

.import pushax, popax 

.import _draw_polygon_color
.import _draw_polygon_top_x
.import _draw_polygon_top_y
.import _draw_polygon_middle_x
.import _draw_polygon_middle_y
.import _draw_polygon_bottom_x
.import _draw_polygon_bottom_y

.import _draw_polygon

;
; draw_polygon_wrapper(struct signed_short *polygons, unsigned short index);
;
.export _draw_polygon_wrapper
_draw_polygon_wrapper:
	stx @index + 1
	
	asl A
	rol @index + 1
	asl A 
	rol @index + 1
	sta @index
	
	jsr popax 
	clc 
	adc @index
	sta ptr1 
	txa 
	adc @index + 1
	sta ptr1 + 1
	; ptr to polygons[i] in ptr1
	
	ldy #signed_short :: color_buffer
	lda (ptr1), Y
	sta _draw_polygon_color
	
	lda #0 + 4
	sta @min_index
	
	ldy #16 + 4 + signed_short :: val + 1
	lda (ptr1), Y
	ldy @min_index
	iny 
	cmp (ptr1), Y ; compare high bytes
	bcs :+
	ldy #16 + 4 + signed_short :: val
	lda (ptr1), Y
	ldy @min_index
	cmp (ptr1), Y ; compare low bytes
	bcs :+
	
	ldx #16
	stx @min_index
	:
	ldy #32 + 4 + signed_short :: val + 1
	lda (ptr1), Y
	ldy @min_index
	iny
	cmp (ptr1), Y ; compare high bytes
	bcs :+
	ldy #32 + 4 + signed_short :: val
	lda (ptr1), Y
	ldy @min_index
	cmp (ptr1), Y ; compare low bytes
	bcs :+
	
	ldx #32 + 4
	stx @min_index
	:

	lda @min_index
	sec
	sbc #4
	sta @min_index
	beq @dont_switch
	
	; temp = polygons[index] ;
	movconst $02, @temp
	movwrd $04, ptr1
	movconst $06, 8
	jsr $FEE7
	; polygons[index] = polygons[min_index]
	movwrd $02, ptr1
	lda ptr1
	clc 
	adc @min_index
	sta $04
	lda ptr1 + 1
	adc #0
	sta $05	
	jsr $FEE7
	; polygons[min_index] = temp
	movwrd $02, $04
	movconst $04, @temp
	jsr $FEE7
	
@dont_switch:
	ldy #4 * 9 + signed_short :: val
	lda (ptr1), Y
	tax 
	iny 
	lda (ptr1), Y
	ldy #4 * 5 + signed_short :: val + 1
	cmp (ptr1), Y
	bcc @less_9_5
	bne @greater_9_5
	txa 
	dey 
	cmp (ptr1), Y
	bcc @less_9_5
@greater_9_5:
	ldy #4 * 4 + signed_short :: val
	lda (ptr1), Y
	sta _draw_polygon_middle_x
	iny 
	lda (ptr1), Y
	sta _draw_polygon_middle_x + 1
	ldy #5 * 4 + signed_short :: val
	lda (ptr1), Y
	sta _draw_polygon_middle_y
	iny 
	lda (ptr1), Y
	sta _draw_polygon_middle_y + 1
	
	ldy #8 * 4 + signed_short :: val
	lda (ptr1), Y
	sta _draw_polygon_bottom_x
	iny 
	lda (ptr1), Y
	sta _draw_polygon_bottom_x + 1
	ldy #9 * 4 + signed_short :: val
	lda (ptr1), Y
	sta _draw_polygon_bottom_y
	iny 
	lda (ptr1), Y
	sta _draw_polygon_bottom_y + 1
	
	bra @actually_draw
@less_9_5:
	ldy #8 * 4 + signed_short :: val
	lda (ptr1), Y
	sta _draw_polygon_middle_x
	iny 
	lda (ptr1), Y
	sta _draw_polygon_middle_x + 1
	ldy #9 * 4 + signed_short :: val
	lda (ptr1), Y
	sta _draw_polygon_middle_y
	iny 
	lda (ptr1), Y
	sta _draw_polygon_middle_y + 1
	
	ldy #4 * 4 + signed_short :: val
	lda (ptr1), Y
	sta _draw_polygon_bottom_x
	iny 
	lda (ptr1), Y
	sta _draw_polygon_bottom_x + 1
	ldy #5 * 4 + signed_short :: val
	lda (ptr1), Y
	sta _draw_polygon_bottom_y
	iny 
	lda (ptr1), Y
	sta _draw_polygon_bottom_y + 1
	
@actually_draw:
	ldy #0 * 4 + signed_short :: val
	lda (ptr1), Y
	sta _draw_polygon_top_x
	iny 
	lda (ptr1), Y
	sta _draw_polygon_top_x + 1
	ldy #1 * 4 + signed_short :: val
	lda (ptr1), Y
	sta _draw_polygon_top_y
	iny 
	lda (ptr1), Y
	sta _draw_polygon_top_y + 1
	
	;bra :+
	;lda _draw_polygon_top_x
	;lda _draw_polygon_middle_x
	;lda _draw_polygon_bottom_x
	;:
	jsr _draw_polygon

	rts 
@index:
	.word 0
@min_index:
	.byte 0
@temp:
	.res 8
	

.importzp sp, sreg 
.import popa

;
; void __fastcall__ set_vram(unsigned char color, unsigned long bytes);
;
.export _set_vram
_set_vram:
	tay 
	
	lda (sp)

	inc sreg
	
	:
	sta $9F23
	dey
	bne :-
	dex
	bne :-
	dec sreg
	bne :-
	
	jsr popa
	rts