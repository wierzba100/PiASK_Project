#include <stdio.h>
#include <omp.h>

int main() {
    int n_threads;

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

    return 0;
}
