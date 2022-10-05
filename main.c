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
		
	scale_move_array(&polygons, 0x280, 0x8000);
	//mergesort_polygons(&polygons);
	draw_polygons_array(&polygons);
	
	while (1) {};
}
