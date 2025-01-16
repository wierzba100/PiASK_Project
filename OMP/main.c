#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include "../Tools/tools.h"

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file_image.png>\n", argv[0]);
        return EXIT_FAILURE;
    }

    int n_threads;
    int width, height;
    unsigned char **gray_image = convert_to_grayscale(argv[1], &width, &height);
    convert_to_png("../Images/output_grayscale.png", gray_image, width, height);

    #pragma omp parallel
    {
        int thread_id = omp_get_thread_num();
        printf("Hello from thread %d\n", thread_id);

        #pragma omp single
        {
            n_threads = omp_get_num_threads();
        }
    }

    printf("Total number of threads: %d\n", n_threads);

    for (int y = 0; y < height; y++) {
        free(gray_image[y]);
    }
    free(gray_image);

    return EXIT_SUCCESS;
}
