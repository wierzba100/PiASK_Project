#ifndef TOOLS_H
#define TOOLS_H

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

static const int Gx[3][3] = {
    {-1, 0, 1},
    {-2, 0, 2},
    {-1, 0, 1}
};

static const int Gy[3][3] = {
    {-1, -2, -1},
    { 0,  0,  0},
    { 1,  2,  1}
};

unsigned char **convert_to_grayscale(const char *filename, unsigned int *out_width, unsigned int *out_height);
void convert_to_png(const char *filename, unsigned char **gray_image, unsigned int width, unsigned int height);

#endif /* TOOLS_H */