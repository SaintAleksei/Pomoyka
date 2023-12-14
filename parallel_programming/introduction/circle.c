#include <stdio.h>
#include <omp.h>

#define NUM_THREADS 4

int main() {
    int shared_var = 0;

    omp_lock_t lock;
    omp_init_lock(&lock);

    #pragma omp parallel num_threads(NUM_THREADS)
    {
        int tid = omp_get_thread_num();                
        while (shared_var < tid);
        omp_set_lock(&lock);
        shared_var++;
        printf("{'tid': %d, 'shared_var': %d}\n", tid, shared_var);
        omp_unset_lock(&lock);
    }

    return 0;
}
