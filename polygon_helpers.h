#ifndef _POLYGON_HELPERS_H
#define _POLYGON_HELPERS_H

#include "polygon_array.h"

void __fastcall__ draw_polygon_wrapper(struct signed_short *polygons, unsigned short index);

void __fastcall__ set_vram(unsigned char color, unsigned long bytes);

#endif