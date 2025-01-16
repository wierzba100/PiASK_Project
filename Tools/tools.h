#ifndef TOOLS_H
#define TOOLS_H

unsigned char **convert_to_grayscale(const char *filename, int *out_width, int *out_height);
void convert_to_png(const char *filename, unsigned char **gray_image, int width, int height);

#endif /* TOOLS_H */