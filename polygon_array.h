#ifndef _POLYGON_ARRAY_H
#define _POLYGON_ARRAY_H

struct signed_short {
	unsigned short val;
	unsigned char sign;
	unsigned char color_buffer;
};

struct dyn_array_short {
	struct signed_short *array;
	unsigned short space_allocated;
	unsigned short length;
};

void draw_polygons_array(struct dyn_array_short *p);

void setup_dyn_array(struct dyn_array_short *p);
void add_point(struct dyn_array_short *p, unsigned char c, unsigned short x0, unsigned char xsign, 
	unsigned short y0, unsigned char ysign, unsigned short z0, unsigned char zsign);
void draw_polygon_wrapper(struct signed_short *polygons, unsigned short index);

void mergesort_polygons(struct dyn_array_short *p);
void mergesort_helper(struct signed_short *from, struct signed_short *to, unsigned short minindex, unsigned short maxindex);

void scale_move_array(struct dyn_array_short *p, unsigned short scalefactor, unsigned short movefactor);

void rotate_z_array(struct dyn_array_short *s, struct dyn_array_short *d, unsigned char adv5);

#endif