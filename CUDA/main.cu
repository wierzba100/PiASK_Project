#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <cmath>
#include <cstdio>
#include <png.h>

#define TILE_SIZE 16

__constant__ int Gx_cuda[3][3] = {
    {-1, 0, 1},
    {-2, 0, 2},
    {-1, 0, 1}
};

__constant__ int Gy_cuda[3][3] = {
    {-1, -2, -1},
    { 0,  0,  0},
    { 1,  2,  1}
};

unsigned char *convert_to_grayscale(const char *filename, unsigned int *out_width, unsigned int *out_height) {
    FILE *fp = fopen(filename, "rb");
    if (!fp)
    {
        perror("Error opening file");
        exit(EXIT_FAILURE);
    }

    png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (!png)
    {
        fclose(fp);
        fprintf(stderr, "Failed to create PNG read struct\n");
        exit(EXIT_FAILURE);
    }

    png_infop info = png_create_info_struct(png);
    if (!info)
    {
        png_destroy_read_struct(&png, NULL, NULL);
        fclose(fp);
        fprintf(stderr, "Failed to create PNG info struct\n");
        exit(EXIT_FAILURE);
    }

    if (setjmp(png_jmpbuf(png)))
    {
        png_destroy_read_struct(&png, &info, NULL);
        fclose(fp);
        fprintf(stderr, "Error during PNG reading\n");
        exit(EXIT_FAILURE);
    }

    png_init_io(png, fp);
    png_read_info(png, info);

    int width = png_get_image_width(png, info);
    int height = png_get_image_height(png, info);
    png_byte color_type = png_get_color_type(png, info);
    png_byte bit_depth = png_get_bit_depth(png, info);

    if (color_type == PNG_COLOR_TYPE_PALETTE)
        png_set_palette_to_rgb(png);

    if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8)
        png_set_expand_gray_1_2_4_to_8(png);

    if (bit_depth == 16)
        png_set_strip_16(png);

    if (color_type == PNG_COLOR_TYPE_RGBA || color_type == PNG_COLOR_TYPE_RGB_ALPHA)
        png_set_strip_alpha(png);

    png_read_update_info(png, info);

    png_bytep *row_pointers = (png_bytep *)malloc(sizeof(png_bytep) * height);
    for (int y = 0; y < height; y++)
    {
        row_pointers[y] = (png_bytep)malloc(png_get_rowbytes(png, info));
    }

    png_read_image(png, row_pointers);

    unsigned char **gray_image = (png_bytep *)malloc(height * sizeof(unsigned char *));
    for (int y = 0; y < height; y++)
    {
        gray_image[y] = (png_bytep)malloc(width * sizeof(unsigned char));
        for (int x = 0; x < width; x++) {
            png_bytep px = &(row_pointers[y][x * 3]);
            gray_image[y][x] = (unsigned char)(0.299 * px[0] + 0.587 * px[1] + 0.114 * px[2]);
        }
    }

    for (int y = 0; y < height; y++)
    {
        free(row_pointers[y]);
    }
    free(row_pointers);

    png_destroy_read_struct(&png, &info, NULL);
    fclose(fp);

    *out_width = width;
    *out_height = height;

    unsigned char* gray_image_flat = (unsigned char*)malloc(width * height * sizeof(unsigned char));
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            gray_image_flat[i * width + j] = gray_image[i][j];
        }
    }

    for (int y = 0; y < height; y++) {
        free(gray_image[y]);
    }
    free(gray_image);

    return gray_image_flat;
}

void convert_to_png(const char *filename, unsigned char *gray_image, unsigned int width, unsigned int height) {
    FILE *fp = fopen(filename, "wb");
    if (!fp) {
        perror("Error opening file for writing");
        exit(EXIT_FAILURE);
    }

    png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (!png) {
        fclose(fp);
        fprintf(stderr, "Failed to create PNG write struct\n");
        exit(EXIT_FAILURE);
    }

    png_infop info = png_create_info_struct(png);
    if (!info) {
        png_destroy_write_struct(&png, NULL);
        fclose(fp);
        fprintf(stderr, "Failed to create PNG info struct\n");
        exit(EXIT_FAILURE);
    }

    if (setjmp(png_jmpbuf(png))) {
        png_destroy_write_struct(&png, &info);
        fclose(fp);
        fprintf(stderr, "Error during PNG writing\n");
        exit(EXIT_FAILURE);
    }

    png_init_io(png, fp);

    png_set_IHDR(
        png, info, width, height,
        8, PNG_COLOR_TYPE_GRAY, PNG_INTERLACE_NONE,
        PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT
    );

    png_write_info(png, info);

    png_bytep *row_pointers = (png_bytep *)malloc(sizeof(png_bytep) * height);
    for (int y = 0; y < height; y++) {
        row_pointers[y] = (png_bytep)malloc(width * sizeof(unsigned char));
        for (int x = 0; x < width; x++) {
            row_pointers[y][x] = gray_image[y * width + x]; // 1D array access
        }
    }

    png_write_image(png, row_pointers);

    for (int y = 0; y < height; y++) {
        free(row_pointers[y]);
    }
    free(row_pointers);

    png_write_end(png, NULL);

    png_destroy_write_struct(&png, &info);
    fclose(fp);
}

__global__ void sobel_filter_kernel(unsigned char *gray_image, unsigned char *output, int width, int height)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x > 0 && x < width - 1 && y > 0 && y < height - 1)
    {
        int gradient_x = 0;
        int gradient_y = 0;

        for (int i = -1; i <= 1; i++)
        {
            for (int j = -1; j <= 1; j++)
            {
                int pixel = gray_image[(y + i) * width + (x + j)];
                gradient_x += pixel * Gx_cuda[i + 1][j + 1];
                gradient_y += pixel * Gy_cuda[i + 1][j + 1];
            }
        }

        int magnitude = (int)sqrtf(gradient_x * gradient_x + gradient_y * gradient_y);
        magnitude = (magnitude > 255) ? 255 : (magnitude < 0 ? 0 : magnitude);

        output[y * width + x] = (unsigned char)magnitude;
    }
}

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s <file_image.png>\n", argv[0]);
        return EXIT_FAILURE;
    }

    unsigned int width, height;
    unsigned char *gray_image = convert_to_grayscale(argv[1], &width, &height);

    unsigned char* d_gray_image;
    unsigned char* d_output;

    cudaMalloc((void**)&d_gray_image, width * height * sizeof(unsigned char));
    cudaMalloc((void**)&d_output, width * height * sizeof(unsigned char));

    cudaMemcpy(d_gray_image, gray_image, width * height * sizeof(unsigned char), cudaMemcpyHostToDevice);

    dim3 blockDim(TILE_SIZE, TILE_SIZE, 1);
    dim3 gridDim((width + TILE_SIZE - 1) / TILE_SIZE, (height + TILE_SIZE - 1) / TILE_SIZE, 1);

    sobel_filter_kernel<<<gridDim, blockDim>>>(d_gray_image, d_output, width, height);

    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess)
    {
        fprintf(stderr, "CUDA error: %s\n", cudaGetErrorString(err));
        return EXIT_FAILURE;
    }

    unsigned char* output = (unsigned char*)malloc(width * height * sizeof(unsigned char));
    cudaMemcpy(output, d_output, width * height * sizeof(unsigned char), cudaMemcpyDeviceToHost);

    convert_to_png("../Images/output_CUDA.png", output, width, height);

    cudaFree(d_gray_image);
    cudaFree(d_output);
    free(gray_image);
    free(output);

    return EXIT_SUCCESS;
}
