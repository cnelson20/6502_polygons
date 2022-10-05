#include "scanline_c.h"
#include "polygon_array.h"
#include "multiply.h"
#include <peekpoke.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

unsigned short sin_table[] = {0, 89, 178, 265, 350, 433, 512, 587, 658, 724, 784, 839, 887, 928, 962, 989, 1008, 1020, 1024};

void draw_polygons_array(struct dyn_array_short *p) {
	unsigned short real_len = p->length << 2;
	unsigned short i;
	
	for (i = 0; i < real_len; i += 12) {
		draw_polygon_wrapper(p->array, i);
	}
}

void setup_dyn_array(struct dyn_array_short *p) {
	p->length = 0;
	p->space_allocated = 8;
	p->array = malloc(16 * sizeof(struct signed_short));
}

void add_point(struct dyn_array_short *p, unsigned char c, unsigned short x0, unsigned char xsign, unsigned short y0, unsigned char ysign, unsigned short z0, unsigned char zsign) {
	struct signed_short s;
	
	if (p->length << 2 >= p->space_allocated) {
		p->space_allocated *= 2;
		p->array = realloc(p->array, p->space_allocated * sizeof (struct signed_short));
	}
	s.val = x0;
	s.sign = xsign;
	s.color_buffer = c;
	p->array[p->length * 4] = s;
	s.val = y0;
	s.sign = ysign;
	p->array[p->length * 4 + 1] = s;
	s.val = z0;
	s.sign = zsign;
	p->array[p->length * 4 + 2] = s;
	
	++p->length;
}

void scale_move_array(struct dyn_array_short *p, unsigned short scalefactor, unsigned short movefactor) {
	unsigned short i;
	unsigned short lenx2 = p->length << 2;
	
	for (i = 0; i < lenx2; i += 4) {
		/* X */
		p->array[i].val = ((long)p->array[i].val * (long)scalefactor) >> 8;
		if (p->array[i].sign) {
			if (p->array[i].val < movefactor) {
				p->array[i].val = movefactor - p->array[i].val;
			} else {
				p->array[i].val = 0;
			}
			p->array[i].sign = 0;
		} else {
			p->array[i].val += movefactor;
		}
		/* Y */
		p->array[i + 1].val = ((long)p->array[i + 1].val * (long)scalefactor) >> 8;
		if (p->array[i + 1].sign) {
			if (p->array[i + 1].val < movefactor) {
				p->array[i + 1].val = movefactor - p->array[i + 1].val;
			} else {
				p->array[i + 1].val = 0;
			}
			p->array[i + 1].sign = 0;
		} else {
			p->array[i + 1].val += movefactor;
		}		
		if (p->array[i + 2].sign) {
			p->array[i + 2].val = 0x8000 - p->array[i + 2].val;
			p->array[i + 2].sign = 0;
		} else {
			p->array[i + 2].val += 0x8000;
		}
	}
}

/*void draw_polygon_wrapper(struct signed_short *polygons, unsigned short index) {
	unsigned short i;
	struct signed_short temp;
	unsigned short min_index = index;
		
	draw_polygon_color = polygons[index].color_buffer;
	
	min_index = index;
	for (i = index + 4; i < index + (3 * 4); i += 4) {
		if (polygons[i+1].val < polygons[min_index+1].val) {
			min_index = i;
		}
	}
	
	if (index != min_index) {
		temp = polygons[index];
		polygons[index] = polygons[min_index];
		polygons[min_index] = temp;
		temp = polygons[index + 1];
		polygons[index + 1] = polygons[min_index + 1];
		polygons[min_index + 1] = temp;
	}
	
	if (polygons[index + 9].val >= polygons[index + 5].val) {
		draw_polygon_top_x = polygons[index].val;
		draw_polygon_top_y = polygons[index + 1].val;
		draw_polygon_middle_x = polygons[index + 4].val;
		draw_polygon_middle_y = polygons[index + 5].val;
		draw_polygon_bottom_x = polygons[index + 8].val;
		draw_polygon_bottom_y = polygons[index + 9].val;
	} else {
		draw_polygon_top_x = polygons[index].val;
		draw_polygon_top_y = polygons[index + 1].val;
		draw_polygon_middle_x = polygons[index + 8].val;
		draw_polygon_middle_y = polygons[index + 9].val;
		draw_polygon_bottom_x = polygons[index + 4].val;
		draw_polygon_bottom_y = polygons[index + 5].val;
	}	
	
	draw_polygon();
	
	return;
}//*/

struct dyn_array_short *src;
struct dyn_array_short *dest;

struct dyn_array_short __mergesort_temp;
void mergesort_polygons(struct dyn_array_short *p) {	
	__mergesort_temp.length = p->length;
	__mergesort_temp.space_allocated = (__mergesort_temp.length * 4) * sizeof(struct signed_short);
	__mergesort_temp.array = malloc(__mergesort_temp.space_allocated);
	
	
	memcpy(__mergesort_temp.array, p->array, (sizeof(struct signed_short) * 4) * __mergesort_temp.length);
	mergesort_helper(__mergesort_temp.array, p->array, 0, __mergesort_temp.length / 3);

	free(__mergesort_temp.array);
}
void mergesort_helper(struct signed_short *from, struct signed_short *to, unsigned short minindex, unsigned short maxindex) {
	unsigned short i, j, index, middle_index;
	unsigned long i_sum, j_sum;
	unsigned char htemp;

	middle_index = maxindex - minindex;
	if (middle_index > 2) {
		middle_index = (minindex + maxindex) >> 1;
		mergesort_helper(to, from, minindex, middle_index);
		mergesort_helper(to, from, middle_index, maxindex);
	} else {
		if (middle_index < 2) {
			return;
		}
		middle_index = minindex + 1;
	}

	middle_index = middle_index * 12; // middle_index * 12
	maxindex = maxindex * 12; // maxindex * 12

	index = minindex * 12; // index = minindex * 12
	i = index;
	j = middle_index;

	i_sum = (unsigned long)(from[i+2].val) + from[i+6].val + from[i+0xA].val;
	j_sum = (unsigned long)(from[j+2].val) + from[j+6].val + from[j+0xA].val;
	while (1) {
		if (i_sum <= j_sum) {
			for (htemp = 0; htemp < 12; ++htemp) {
				to[index + htemp] = from[i + htemp];
			}
			i += 12;
			index += 12;
			if (i >= middle_index) {
				break;
			}
			i_sum = (unsigned long)(from[i+2].val) + from[i+6].val + from[i+0xA].val;
		} else {
			for (htemp = 0; htemp < 12; ++htemp) {
				to[index + htemp] = from[j + htemp];
			}
			j += 12;
			index += 12;
			if (j >= maxindex) {
				break;
			}
			j_sum = (unsigned long)(from[j+2].val) + from[j+6].val + from[j+0xA].val;
		}
	}
	for (; i < middle_index; ++i) {
		to[index] = from[i];
		++index;
	}
	for (; j < maxindex; ++j) {	
		to[index] = from[j];
		++index;
	}

}

unsigned short sin, cos;
unsigned char sin_sign, cos_sign;	

unsigned char anglediv5;

struct signed_short temp1, temp2;
/* 
	Rotates each polygon in S by ADV5 * 5 degrees and copies it to D

*/
void rotate_z_array(struct dyn_array_short *s, struct dyn_array_short *d, unsigned char adv5) {
	unsigned short i, array_real_len;

	src = s;
	dest = d;
	anglediv5 = adv5;
	
	if (anglediv5 >= 36) {
		sin_sign = 1;
		if (anglediv5 >= 54) {
			// Q4
			cos_sign = 0;
			anglediv5 = 72 - anglediv5;
		} else {
			// Q3
			cos_sign = 1;
			anglediv5 -= 36;
		}
	} else {
		sin_sign = 0;
		if (anglediv5 > 18) {
			// Q2
			cos_sign = 1;
			anglediv5 = 36 - anglediv5;
		} else {
			// Q1
			cos_sign = 0;
		}
	}
	
	__asm__ ("lda %v", anglediv5);
	__asm__ ("asl A");
	__asm__ ("tax");
	__asm__ ("lda %v, X", sin_table);
	__asm__ ("sta %v", sin);
	__asm__ ("lda %v + 1, X", sin_table);
	__asm__ ("sta %v + 1", sin);

	__asm__ ("stx %v", cos);
	__asm__ ("lda #18 * 2");
	__asm__ ("sec");
	__asm__ ("sbc %v", cos);
	__asm__ ("tax");
	__asm__ ("lda %v, X", sin_table);
	__asm__ ("sta %v", cos);
	__asm__ ("lda %v + 1, X", sin_table);
	__asm__ ("sta %v + 1", cos);
	
	if (dest->length != src->length) {
		dest->length = src->length;
		dest->space_allocated = (dest->length * 4) * sizeof(struct signed_short);
		dest->array = malloc(dest->space_allocated);
	}
	
	array_real_len = dest->length << 2;
	for (i = 0; i < array_real_len; i += 4) {
		/* X1 = Cos(t)X0 - Sin(t)Y0 */
		temp1.val = ((unsigned long)src->array[i].val * cos >> 10);
		temp1.sign = cos_sign ^ src->array[i].sign;
		temp2.val = ((unsigned long)src->array[i + 1].val * sin >> 10);
		temp2.sign = 1 ^ sin_sign ^ src->array[i + 1].sign;
		
		if (temp1.sign == temp2.sign) {
			dest->array[i].sign = temp1.sign;
			dest->array[i].val = temp1.val + temp2.val;
		} else if (temp1.val >= temp2.val) {
			dest->array[i].sign = temp1.sign;
			dest->array[i].val = temp1.val - temp2.val;
		} else {
			dest->array[i].sign = temp2.sign;
			dest->array[i].val = temp2.val - temp1.val;
		}
		dest->array[i].color_buffer = src->array[i].color_buffer;
		
		/* Y1 = Sin(t)X0 + Cos(t)Y0 */
		temp1.val = ((unsigned long)src->array[i].val * sin >> 10);
		temp1.sign = sin_sign ^ src->array[i].sign;
		temp2.val = ((unsigned long)src->array[i + 1].val * cos >> 10);
		temp2.sign = cos_sign ^ src->array[i + 1].sign;
		
		if (temp1.sign == temp2.sign) {
			dest->array[i + 1].sign = temp1.sign;
			dest->array[i + 1].val = temp1.val + temp2.val;
		} else if (temp1.val >= temp2.val) {
			dest->array[i + 1].sign = temp1.sign;
			dest->array[i + 1].val = temp1.val - temp2.val;
		} else {
			dest->array[i + 1].sign = temp2.sign;
			dest->array[i + 1].val = temp2.val - temp1.val;
		}
		
		//printf("dest->array[i+1]: %c%hu\n\n", dest->array[i+1].sign ? '-' : '+', dest->array[i+1].val);
		/* Z1 = Z0 */
		dest->array[i + 2] = src->array[i + 2];
	}
}