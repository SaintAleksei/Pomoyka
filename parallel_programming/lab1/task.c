#include <math.h>
#include <errno.h>
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>

/*
 * All tasks are in one file to avoid copy/paste
 * Tasks are defined by defines TASK*
 */

#if defined(TASK1_SIMPLE) || defined(TASK2_SIMPLE) || defined(TASK3_SIMPLE)

#include <time.h>

#endif

#if defined(TASK1_OPENMP) || defined(TASK3_OPENMP)

#include <omp.h>

unsigned long num_threads = 1;

#endif

#if defined(TASK1_MPI) || defined(TASK2_MPI)

#include <mpi.h>

#endif

// Array initialization function
static void   init         (double *arr, unsigned long isize, unsigned long jsize);
// Main array computation function
static double compute      (double *arr, unsigned long isize, unsigned long jsize);
static void   usage        (char **argv);
#ifdef SAVE_RESULTS
static void   save_results (double *arr, unsigned long isize, unsigned long jsize);
#endif

int main(int argc, char **argv)
{
  // Arguments parsing

  if (argc < 3)
  {
    usage(argv);
    exit(EXIT_FAILURE);
  }

  char *endptr = NULL;
        errno  = 0;
  unsigned long isize = strtoul(argv[1], &endptr, 10);
  if ( errno  == ERANGE || 
      *endptr != '\0'   || 
       isize  == 0)
  {
    fprintf(stderr, "Bad isize value\n");
    exit(EXIT_FAILURE);
  }

  unsigned long jsize = strtoul(argv[2], &endptr, 10);
  if ( errno  == ERANGE || 
      *endptr != '\0'   ||
       jsize  == 0)
  {
    fprintf(stderr, "Bad jsize value\n");
    exit(EXIT_FAILURE);
  }

#if defined(TASK1_OPENMP) || defined(TASK3_OPENMP)
  if (argc >= 4)
  {
    num_threads = strtoul(argv[3], &endptr, 10);
    if ( errno  == ERANGE || 
        *endptr != '\0'   ||
         jsize  == 0)
    {
      fprintf(stderr, "Bad num_threads value\n");
      exit(EXIT_FAILURE);
    }
  }
#endif

  // Array allocation
  double *arr = malloc(isize * jsize * sizeof(arr[0]));
  if (arr == NULL)
  {
    fprintf(stderr, "malloc failure\n");
    exit(EXIT_FAILURE);
  }

  // Array initialization
  init(arr, isize, jsize);

  // Array computation with time measuring
  double time = compute(arr, isize, jsize);

  printf("%lg\n", time);

#ifdef SAVE_RESULTS
  // Results saving
  save_results(arr, isize, jsize);
#endif

  free(arr);
  exit(EXIT_SUCCESS);
}

void usage(char **argv)
{
#if defined(TASK1_OPENMP) || defined(TASK1_OPENMP)
    fprintf(stderr, "Usage: %s <isize> <jsize> [<num_threads>]\n", argv[0]);
#else
    fprintf(stderr, "Usage: %s <isize> <jsize>\n", argv[0]);
#endif
}

#define ARR(i, j) (arr[(i) * jsize + (j)])

#ifdef SAVE_RESULTS
static void save_results(double *arr, unsigned long isize, unsigned long jsize)
{
  #ifndef RESULTS_FILE

    #define RESULTS_FILE "results.csv"

  #endif

  FILE *ff = fopen(RESULTS_FILE, "w");
  if (ff == NULL)
  {
    fprintf(stderr, "fopen failure\n");
    exit(EXIT_FAILURE);
  }

  unsigned long i = 0;
  unsigned long j = 0;
  for(i = 0; i < isize; i++)
  {
    for (j = 0; j < jsize - 1; j++)
    {
      fprintf(ff, "%.4lg, ", ARR(i, j));
    }
    fprintf(ff, "%.4lg\n", ARR(i, jsize - 1));
  }

  fclose(ff);
}
#endif

static void init(double *arr, unsigned long isize, unsigned long jsize)
{
  unsigned long i = 0;
  unsigned long j = 0;
  for (i = 0; i < isize; i++)
  {
    for (j = 0; j < jsize; j++)
    {
      ARR(i, j) = 10 * i + j;
    }
  }
}

#if defined(TASK1_MPI)
static void get_task(size_t  size,  size_t  nworkers, size_t id,
                     size_t* start, size_t* bs)
{
  *bs     = size / nworkers;
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
  *start  = id * *bs + MIN(id, size % nworkers);
#undef MIN
  *bs    += (id + 1 > size % nworkers) ? 0 : 1;
}
#endif

// main computation function
static double compute(double *arr, unsigned long isize, unsigned long jsize)
{
  double time = 0.0;

#if defined(TASK1_SIMPLE)   // main task simple implementation

  time = clock();

  for (unsigned long i = 0; i < isize; i++)
  {
    for (unsigned long j = 0; j < jsize; j++)
    {
      ARR(i, j) = sin(2 * ARR(i, j));
    }
  }

  time = (clock() - time) / CLOCKS_PER_SEC;

#elif defined(TASK1_OPENMP) // main task OpenMP implementation

  time = omp_get_wtime();

  #pragma omp parallel for num_threads(num_threads)
  for (unsigned long i = 0; i < isize; i++)
  {
    for (unsigned long j = 0; j < jsize; j++)
    {
      ARR(i, j) = sin(2 * ARR(i, j));
    }
  }

  time = omp_get_wtime() - time;

#elif defined(TASK1_MPI)    // main task MPI implementation

  MPI_Init(NULL, NULL);

  unsigned rank = 0;
  MPI_Comm_rank(MPI_COMM_WORLD, (int*) &rank);
  unsigned size = 0;
  MPI_Comm_size(MPI_COMM_WORLD, (int*) &size);

  size_t worker_bs = 0;
  size_t start     = 0;
  get_task(isize, size, rank, &start, &worker_bs);

#ifdef DEBUG
  printf("[INF] Worker #%d has {'start': %lu, 'worker_bs': %lu}\n",
         rank, start, worker_bs);
#endif

  time = MPI_Wtime();

  for (unsigned long i = start; i < start + worker_bs; i++)
  {
    for (unsigned long j = 0; j < jsize; j++)
    {
      ARR(i, j) = sin(2 * ARR(i, j));
    }
  }

  if (rank != 0)
  {
      MPI_Send(arr + start * jsize, worker_bs * jsize, 
               MPI_DOUBLE, 0, 0, MPI_COMM_WORLD);
  }
  else
  {
      for (unsigned i = 1; i < size; i++)
      {
          get_task(isize, size, i, &start, &worker_bs);
          MPI_Recv(arr + start * jsize, worker_bs * jsize,
                   MPI_DOUBLE, i, 0, MPI_COMM_WORLD, NULL);
      }
  }

  time = MPI_Wtime() - time;

  MPI_Finalize();
  
  if (rank != 0)
  {
      exit(EXIT_SUCCESS);
  }

#elif defined(TASK2_SIMPLE) // second task simple implementation

  time = clock();

  for (unsigned long i = 3; i < isize; i++)
  { 
    for (unsigned long j = 0; j < jsize - 2; j++)
    {
      ARR(i, j) = sin(3 * ARR(i - 3, j + 2));
    }
  }

  time = (clock() - time) / CLOCKS_PER_SEC;

#elif defined(TASK2_MPI)    // second task MPI implementation

  MPI_Init(NULL, NULL);

  unsigned rank = 0;
  MPI_Comm_rank(MPI_COMM_WORLD, (int*) &rank);
  unsigned size = 0;
  MPI_Comm_size(MPI_COMM_WORLD, (int*) &size);

  assert(size == 3);

  MPI_Request* requests_a = malloc(size * sizeof(*requests_a));
  if (!requests_a)
  {
    fprintf(stderr, "malloc falilure\n");
    exit(EXIT_FAILURE);
  }

  time = MPI_Wtime();

  assert(isize > 3);
  assert(jsize > 2);
  for (unsigned long i = 3 + rank; i < isize; i += size)
  {
    for (unsigned long j = 0; j < jsize - 2; j++)
    {
      ARR(i, j) = sin(3 * ARR(i - 3, j + 2));
    }

    if (rank != 0)
    {
        MPI_Isend(arr + i * jsize, jsize, 
                 MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, requests_a + rank);
    }
    else
    {
        for (unsigned k = 1; k < size && i + k < isize; k++)
        {
            MPI_Irecv(arr + (i + k) * jsize, jsize,
                      MPI_DOUBLE, k, 0, MPI_COMM_WORLD, requests_a + k);
        }
    }
  }

  if (rank == 0)
  {
    for (size_t i = 1; i < size; i++) 
    {
      MPI_Status status;
      MPI_Wait(requests_a + i, &status);
      // TODO: Check status?
    }
  }

  time = MPI_Wtime() - time;

  free(requests_a);

  MPI_Finalize();

  if (rank != 0)
  {
      exit(EXIT_SUCCESS);
  }

#elif defined(TASK3_SIMPLE) // third task simple implementation

  time = clock();

  assert(isize > 3);
  for (unsigned long i = 0; i < isize - 3; i++)
  { 
    for (unsigned long j = 2; j < jsize; j++)
    {
      ARR(i, j) = sin(0.1 * ARR(i + 3, j - 2));
    }
  }

  time = (clock() - time) / CLOCKS_PER_SEC;

#elif defined(TASK3_OPENMP) // third task OpenMP implementation

  double *copy = malloc(isize * jsize * sizeof(*copy));
  if (!copy)
  {
    fprintf(stderr, "malloc failure\n");
    exit(EXIT_FAILURE);
  }

  #pragma omp parallel for num_threads(num_threads)
  for (size_t i = 0; i < isize; i++)
  {
    for (size_t j = 0; j < jsize; j++)
    {
      copy[i * jsize + j] = ARR(i, j);  
    }
  }

  time = omp_get_wtime();

  assert(isize > 3);
  #pragma omp parallel for num_threads(num_threads)
  for (unsigned long i = 0; i < isize - 3; i++)
  {
    for (unsigned long j = 2; j < jsize; j++)
    {
      ARR(i, j) = sin(0.1 * copy[(i + 3) * jsize + j - 2]);
    }
  }

  time = omp_get_wtime() - time;

  free(copy);

#else 

  #error "Task is not chosen"

#endif

  (void) arr;
  (void) isize;
  (void) jsize;

  return time;
}
