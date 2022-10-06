#include <peekpoke.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cbm.h>

#include "scanline_c.h"
#include "main.h"
#include "polygon_array.h"
#include "polygon_helpers.h"
#include "waitforjiffy.h"

struct dyn_array_short polygons, temppolygons;

unsigned char i;

void main() {	
	setup_dyn_array(&polygons);

	/*
	add_point(&polygons, 2, 0x1000, 1, 0x1000, 1, 0x0000, 0);
	add_point(&polygons, 0, 0x0000, 0, 0x0A00, 1, 0x0000, 0);
	add_point(&polygons, 0, 0x0000, 0, 0x1000, 0, 0x0000, 0);
	*/
	
	add_point(&polygons, 2, 0x1000, 1, 0x1000, 1, 0x0000, 0);	
	add_point(&polygons, 0, 0x0000, 0, 0x1000, 0, 0x0000, 0);
	add_point(&polygons, 0, 0x0000, 0, 0x0A00, 1, 0x0000, 0);
	add_point(&polygons, 4, 0x1000, 0, 0x1000, 1, 0x0000, 0);
	add_point(&polygons, 0, 0x0000, 0, 0x0A00, 1, 0x0000, 0);
	add_point(&polygons, 0, 0x0000, 0, 0x1000, 0, 0x0000, 0);	

	/* Enable bitmap */
	POKE(0x9F34, 7);
	POKE(0x9F36, 0);
	
	POKE(0x9F25, 0);
	POKE(0x9F2A, 64);
	POKE(0x9F2B, 64);
	
	POKE(0x9F20, 0);
	POKE(0x9F21, 0);
	POKE(0x9F22, 0x10);
	set_vram(0, 76800);
		
	i = 0;
	while (1) {
	int j;
	rotate_z_array(&polygons, &temppolygons, i);
	scale_move_array(&temppolygons, 0x280, 0x8000);
	
	for (j = 0; j < polygons.length * 4; ++j) {
		POKEW(0x8000 + j * 4, polygons.array[j].val);
		POKEW(0x8000 + j * 4 + 2, polygons.array[j].sign);
		POKEW(0x8000 + j * 4 + 3, polygons.array[j].color_buffer);
	}
	for (j = 0; j < polygons.length * 4; ++j) {
		POKEW(0x8040 + j * 4, temppolygons.array[j].val);
		POKEW(0x8040 + j * 4 + 2, temppolygons.array[j].sign);
		POKEW(0x8040 + j * 4 + 3, temppolygons.array[j].color_buffer);
	}	
	
	draw_polygons_array(&temppolygons);
	waitforjiffy();
	
	while (1) {
		__asm__ ("jsr $FFE4");
		__asm__ ("cmp #$20");
		__asm__ ("bne %g", label);
		POKE(0x9F20, 0);
		POKE(0x9F21, 0);
		POKE(0x9F22, 0x10);
		break;
		label:
		;
	}
	
	++i;
	if (i >= 72) { i = 0; }
	}
	// $18 breaks 
	// $3F starts again
	
}
