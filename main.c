#include <peekpoke.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cbm.h>

#include "scanline_c.h"
#include "main.h"
#include "polygon_array.h"
#include "waitforjiffy.h"

struct dyn_array_short polygons, temppolygons;

unsigned char keyboard_input[3];
unsigned char old_keyboard_input[2];

unsigned char key_presses_direction[16] = {
//  0     1     2     3     4     5   6   7   8     9   a   b  c     d   e   f
	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 45, 27, 36, 0xFF, 63, 9, 00, 0xFF, 54, 18, 0xFF
};

unsigned short x_pos, y_pos, temp_pos, old_x_pos, old_y_pos;

unsigned char keyboard_temp;
unsigned char direction, old_direction;
unsigned char addr_to_write;

void main() {	
	addr_to_write = 0;
	x_pos = 64 << 4;
	y_pos = 64 << 4;
	old_x_pos = 0xFFFF;
	old_y_pos = 0xFFFF;
	
	setup_dyn_array(&polygons);

	add_point(&polygons, 2, 0x1000, 1, 0x1000, 1, 0, 0);
	add_point(&polygons, 0, 0x0000, 0, 0x0A00, 1, 0, 0);
	add_point(&polygons, 0, 0x0000, 0, 0x1000, 0, 0, 0);
	
	add_point(&polygons, 4, 0x1000, 0, 0x1000, 1, 0, 0);
	add_point(&polygons, 0, 0x0000, 0, 0x0A00, 1, 0, 0);
	add_point(&polygons, 0, 0x0000, 0, 0x1000, 0, 0, 0);	

	/* Enable sprite */
	POKE(0x9F25, 0);
	__asm__ ("lda $9F29");
	__asm__ ("ora #$40");
	__asm__ ("sta $9F29");
	
	POKE(0x9F20, 0);
	POKE(0x9F21, 0xFC);
	POKE(0x9F22, 0x11); // start of sprite memory
	
	POKE(0x9F23, 0); // low part of sprite graphics location
	POKE(0x9F23, 0x88); // 8bpp, high part of sprite graphics location
	/*POKE(0x9F23, 0x08);*/
	
	POKE(0x9F23, 0); // set xpos to 0
	POKE(0x9F23, 0);
	POKE(0x9F23, 0); // set ypos to 0
	POKE(0x9F23, 0);
	
	POKE(0x9F23, 0xC);
	POKE(0x9F23, 0xF0);
		
	direction = 0;
	old_direction = 0xFF;
	
	printf("Polygons!\n");
	
	while (1) {
		//__asm__ ("jsr $FF53");
		__asm__ ("lda #0");
		__asm__ ("jsr $FF56");
		__asm__ ("sta %v", keyboard_input);
		__asm__ ("stx %v + 1", keyboard_input);
		__asm__ ("sty %v + 2", keyboard_input);
		
		keyboard_temp = keyboard_input[0] & 0xF;
		if (!(keyboard_temp & 0x1)) {
			x_pos += 12;
		}
		if (!(keyboard_temp & 0x2)) {
			x_pos -= 12;
			if (x_pos >= 0xFF00) {
				x_pos = 0;
			}
		}
		if (!(keyboard_temp & 0x4)) {
			y_pos += 12;
		}
		if (!(keyboard_temp & 0x8)) {
			y_pos -= 12;
			if (y_pos >= 0xFF00) {
				y_pos = 0;
			}
		}
		
		__asm__ ("ldx %v", keyboard_temp);
		__asm__ ("lda %v,X", key_presses_direction);
		__asm__ ("cmp #$FF");
		__asm__ ("beq %g", branchAheadLabel);
		__asm__ ("sta %v", direction);
		branchAheadLabel:
			
		keyboard_temp = 
			((keyboard_input[0] & 0x80) >> 5) | // Down (B)
			((keyboard_input[1] & 0x40) >> 3) | // Up (X)
			((keyboard_input[0] & 0x40) >> 5) | // Left (Y)
			((keyboard_input[1] & 0x80) >> 7); // Right (A)		
		if (keyboard_temp != 0xF) {
			__asm__ ("ldx %v", keyboard_temp);
			__asm__ ("lda %v,X", key_presses_direction);
			__asm__ ("cmp #$FF");
			__asm__ ("beq %g", branchAheadLabel2);
			__asm__ ("sta %v", direction);
			branchAheadLabel2:
			;
		}		
		
		if (x_pos != old_x_pos || y_pos != old_y_pos) {
			old_x_pos = x_pos;
			old_y_pos = y_pos;
			/* Set sprite pos */
			POKE(0x9F20, 0x05);
			POKE(0x9F21, 0xFC);
			POKE(0x9F22, 0x19);
			
			__asm__ ("lda %v + 1", y_pos);
			__asm__ ("ldx %v", y_pos);
			__asm__ ("lsr A");
			__asm__ ("tay");
			__asm__ ("txa");
			__asm__ ("ror A");
			__asm__ ("tax");
			__asm__ ("tya");
			
			__asm__ ("lsr A");
			__asm__ ("tay");
			__asm__ ("txa");
			__asm__ ("ror A");
			__asm__ ("tax");
			__asm__ ("tya");
			
			__asm__ ("lsr A");
			__asm__ ("tay");
			__asm__ ("txa");
			__asm__ ("ror A");
			__asm__ ("tax");
			__asm__ ("tya");
			
			__asm__ ("lsr A");
			__asm__ ("tay");	
			__asm__ ("txa");
			__asm__ ("ror A");
			__asm__ ("sec");
			__asm__ ("sbc #32");
			__asm__ ("tax");
			__asm__ ("tya");
			__asm__ ("sbc #0");
			__asm__ ("sta $9F23");
			
			__asm__ ("stx $9F23");
			

			__asm__ ("lda %v + 1", x_pos);
			__asm__ ("ldx %v", x_pos);
			__asm__ ("lsr A");
			__asm__ ("tay");
			__asm__ ("txa");
			__asm__ ("ror A");
			__asm__ ("tax");
			__asm__ ("tya");
			
			__asm__ ("lsr A");
			__asm__ ("tay");
			__asm__ ("txa");
			__asm__ ("ror A");
			__asm__ ("tax");
			__asm__ ("tya");
			
			__asm__ ("lsr A");
			__asm__ ("tay");
			__asm__ ("txa");
			__asm__ ("ror A");
			__asm__ ("tax");
			__asm__ ("tya");
			
			__asm__ ("lsr A");
			__asm__ ("tay");	
			__asm__ ("txa");
			__asm__ ("ror A");
			__asm__ ("sec");
			__asm__ ("sbc #32");
			__asm__ ("tax");
			__asm__ ("tya");
			__asm__ ("sbc #0");
			__asm__ ("sta $9F23");
			
			__asm__ ("stx $9F23");
		}
			
		if (direction != old_direction) {
			POKE(0x9F20, 0);
			POKE(0x9F21, addr_to_write);
			POKE(0x9F22, 0x11);
			set_vram(0, 0x1000);
			
			rotate_z_array(&polygons, &temppolygons, direction == 0 ? 0 : 72 - direction);
			scale_move_array(&temppolygons, 1, 0x2000);
			mergesort_polygons(&polygons);
			draw_polygons_array(&temppolygons, addr_to_write);

			/* modify sprite buffer */
			POKE(0x9F20, 0);
			POKE(0x9F21, 0xFC);
			POKE(0x9F22, 0x11);
			POKE(0x9F23, addr_to_write << 3);
			addr_to_write ^= 0x10;
		}
		old_direction = direction;
		old_keyboard_input[0] = keyboard_input[0];
		old_keyboard_input[1] = keyboard_input[1];
		
		waitforjiffy();
	}
	
	return;
}
