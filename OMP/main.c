#include <omp.h>
#include "../Tools/tools.h"

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s <file_image.png>\n", argv[0]);
        return EXIT_FAILURE;
    }

    unsigned int width, height;
    unsigned char **gray_image = convert_to_grayscale(argv[1], &width, &height);

    unsigned char** output = (unsigned char**)calloc(height, sizeof(unsigned char*));
    for (unsigned int i = 0; i < height; i++)
    {
        output[i] = (unsigned char*)calloc(width, sizeof(unsigned char));
        if (output[i] == NULL)
        {
            fprintf(stderr, "Allocation error %u\n", i);
            for (unsigned int j = 0; j < i; j++)
            {
                free(output[j]);
                free(gray_image[j]);
                
            }
            free(output);
            free(gray_image);

            return EXIT_FAILURE;
        }
    }

    #pragma omp parallel for collapse(2) schedule(dynamic)
        for (int y = 1; y < height - 1; y++)
        {
            for (int x = 1; x < width - 1; x++)
            {
                int gradient_x = 0;
                int gradient_y = 0;

                for (int i = -1; i <= 1; i++)
                {
                    for (int j = -1; j <= 1; j++)
                    {
                        gradient_x += gray_image[y + i][x + j] * Gx[i + 1][j + 1];
                        gradient_y += gray_image[y + i][x + j] * Gy[i + 1][j + 1];
                    }
                }

                int magnitude = (int)sqrt(gradient_x * gradient_x + gradient_y * gradient_y);
                magnitude = (magnitude > 255) ? 255 : (magnitude < 0 ? 0 : magnitude);

                output[y][x] = (unsigned char)magnitude;
            }
        }


    convert_to_png("../Images/output.png", output, width, height);

    for (int y = 0; y < height; y++) {
        free(gray_image[y]);
        free(output[y]);
    }
    free(gray_image);
    free(output);

    return EXIT_SUCCESS;
}
