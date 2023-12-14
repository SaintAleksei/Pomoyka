#include <stdio.h>
#include <omp.h>
 
int main (void)
{
    #pragma omp parallel num_threads(4)
    {
        int tid         = omp_get_thread_num() ;
        int num_threads = omp_get_num_threads();
        printf ("{'tid': %d, 'num_threads': %d}\n", tid, num_threads);
    }
    return 0;
}
