#ifndef _SCANLINE_H
#define _SCANLINE_H

extern unsigned short draw_polygon_addr;
extern unsigned char draw_polygon_color;

extern unsigned short draw_polygon_top_x;
extern unsigned short draw_polygon_top_y;

extern unsigned short draw_polygon_middle_x;
extern unsigned short draw_polygon_middle_y;

extern unsigned short draw_polygon_bottom_x;
extern unsigned short draw_polygon_bottom_y;

void draw_polygon();

#endif