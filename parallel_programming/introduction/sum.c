#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <string.h>
#include <errno.h>

#ifndef NUM_THREADS
#define NUM_THREADS 1
#endif
   
static void get_block(size_t  size,  size_t  nworkers, size_t id,
                     size_t* start, size_t* bs)
{
  *bs     = size / nworkers;
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
  *start  = id * *bs + MIN(id, size % nworkers);
#undef MIN
  *bs    += (id + 1 > size % nworkers) ? 0 : 1;
}

static inline double get_task(size_t num)
{
  return 1.0 + num;
}
 
int main(int argc, char **argv)
{
  if (argc < 2)
  {
    fprintf(stderr, "Usage: %s <N>\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  char *endptr = NULL;
        errno  = 0;
  unsigned long N = strtoul(argv[1], &endptr, 10);
  if ( errno  != 0    ||
      *endptr != '\0' ||
       N      <  1)
  {
    fprintf(stderr, "Bad N vavlue\n");
    exit(EXIT_FAILURE);
  }

  double sum_array[NUM_THREADS];
  for(int i = 0; i < NUM_THREADS; i++)
  {
    sum_array[i] = 0.0;
  }

  #pragma omp parallel num_threads(NUM_THREADS)
  {
    unsigned tid   = omp_get_thread_num();
    size_t   start = 0;
    size_t   bs    = 0;
    get_block(N - 1, omp_get_num_threads(), tid,
              &start, &bs);

    printf("{'tid': %u, 'start': %lu, 'bs': %lu}\n", tid, start, bs);

    for (size_t i = start; i < start + bs; i++)
    {
      sum_array[tid] += 1.0 / get_task(i);
    }
  }

  for(int i = 1; i < NUM_THREADS; i++)
  {
    sum_array[0] += sum_array[i];
  }

  printf("%lg\n", sum_array[0]);

  exit(EXIT_SUCCESS);
}
