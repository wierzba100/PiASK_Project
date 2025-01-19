#include <mpi.h>
#include "../Tools/tools.h"

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s <file_image.png>\n", argv[0]);
        return EXIT_FAILURE;
    }

    MPI_Init(&argc, &argv);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    unsigned int width, height;
    unsigned char **gray_image = NULL;

    if (rank == 0)
    {
        gray_image = convert_to_grayscale(argv[1], &width, &height);
    }

    MPI_Bcast(&width, 1, MPI_UNSIGNED, 0, MPI_COMM_WORLD);
    MPI_Bcast(&height, 1, MPI_UNSIGNED, 0, MPI_COMM_WORLD);

    if (rank != 0)
    {
        gray_image = (unsigned char**)calloc(height, sizeof(unsigned char*));
        for (unsigned int i = 0; i < height; i++)
        {
            gray_image[i] = (unsigned char*)calloc(width, sizeof(unsigned char));
        }
    }

    for (unsigned int i = 0; i < height; i++)
    {
        MPI_Bcast(gray_image[i], width, MPI_UNSIGNED_CHAR, 0, MPI_COMM_WORLD);
    }

    unsigned char **output = (unsigned char**)calloc(height, sizeof(unsigned char*));
    for (unsigned int i = 0; i < height; i++)
    {
        output[i] = (unsigned char*)calloc(width, sizeof(unsigned char));
    }

    int rows_per_process = height / size;
    int start_row = rank * rows_per_process;
    int end_row = (rank == size - 1) ? height : start_row + rows_per_process;

    for (int y = (start_row > 0 ? start_row : 1); y < (end_row < height - 1 ? end_row : height - 1); y++)
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

    if (rank != 0)
    {
        for (int y = start_row; y < end_row; y++)
        {
            MPI_Send(output[y], width, MPI_UNSIGNED_CHAR, 0, y, MPI_COMM_WORLD);
        }
    }
    else
    {
        for (int src = 1; src < size; src++)
        {
            int src_start_row = src * rows_per_process;
            int src_end_row = (src == size - 1) ? height : src_start_row + rows_per_process;

            for (int y = src_start_row; y < src_end_row; y++)
            {
                MPI_Recv(output[y], width, MPI_UNSIGNED_CHAR, src, y, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            }
        }

        convert_to_png("../Images/output_MPI.png", output, width, height);
    }

    for (int y = 0; y < height; y++)
    {
        free(gray_image[y]);
        free(output[y]);
    }
    free(gray_image);
    free(output);

    MPI_Finalize();
    return EXIT_SUCCESS;
}
