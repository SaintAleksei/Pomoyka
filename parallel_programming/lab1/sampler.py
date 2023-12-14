#!/usr/bin/python3

from matplotlib import pyplot as plt
import subprocess
import numpy
import json
import argparse
import os

def sample_task(build='build/', overwrite=False, 
                isize=10000, jsize=10000, threads=[i for i in range(1, 9)], samples=10,
                skip_openmp=False, skip_mpi=False, task_name='TASK1', v=False, skip_plot=False):

  def verbose(text):
    if v:
      print(text)

  sampling_file = f'{task_name}_{isize}_{jsize}_{samples}.json'

  if not os.path.exists(os.path.join(sampling_file)) or overwrite:
    verbose(f'[INF] Sampling data for {task_name}') 
    verbose(f'[INF] isize   = {isize}')
    verbose(f'[INF] jsize   = {jsize}')
    verbose(f'[INF] threads = {threads}')
    verbose(f'[INF] samples = {samples}')

    sampling = {}

    simple = os.path.join(build, f'{task_name}_SIMPLE.elf')
    verbose(f'[INF] Sampling \'simple\' with executable \'{simple}\'')
    if not os.path.exists(simple):
      verbose(f'[ERR] Executable \'{simple}\' not found')
      exit(1)

    sampling['simple'] = []
    for _ in range(samples):
      out = subprocess.run([simple, str(isize), str(jsize)], stdout=subprocess.PIPE, text=True).stdout
      sampling['simple'].append(float(out))

    if not skip_openmp:
      openmp = os.path.join(build, f'{task_name}_OPENMP.elf')
      verbose(f'[INF] Sampling \'openmp\' with executable \'{openmp}\'')
      if not os.path.exists(simple):
        verbose(f'[ERR] Executable \'{openmp}\' not found')
        exit(1)

      sampling['openmp'] = {}
      for i in threads:
        verbose(f'[INF] Sampling with \'{i}\' threads')
        sampling['openmp'][i] = []
        for _ in range(samples):
          out = subprocess.run([openmp, str(isize), str(jsize), str(i)], stdout=subprocess.PIPE, text=True).stdout

          try:
              val = float(out.split('\n')[-2])
          except:
              val = None

          sampling['openmp'][i].append(val)

    if not skip_mpi:
      mpi = os.path.join(build, f'{task_name}_MPI.elf')
      verbose(f'[INF] Sampling \'mpi\' with executable \'{mpi}\'')
      if not os.path.exists(simple):
        verbose(f'[ERR] Executable \'{mpi}\' not found')
        exit(1)

      sampling['mpi'] = {}
      for i in threads:
        verbose(f'[INF] Sampling with \'{i}\' threads')
        sampling['mpi'][i] = []
        for _ in range(samples):
          out = subprocess.run(['mpirun', '-np', str(i), mpi, str(isize), str(jsize)], stdout=subprocess.PIPE, text=True).stdout

          try:
              val = float(out.split('\n')[-2])
          except:
              val = None

          sampling['mpi'][i].append(val)

    with open(sampling_file, 'w') as f:
      f.write(json.dumps(sampling, indent=4))
  else:
    verbose(f'[INF] Using existing sampling file \'{sampling_file}\'')

  if skip_plot:
    exit(0)

  with open(sampling_file, 'r') as f:
    sampling = json.loads(f.read())

  def plot_time(task, data):
    x  = numpy.empty((0,))
    y  = numpy.empty((0,))
    for k, v in data.items():
      if None in v:
        continue
      x = numpy.append(x, float(k))
      y = numpy.append(y, sum(v) / len(v))

    fig, ax = plt.subplots(figsize=(16, 10))
    ax.set_title(f'Time for {task}')
    ax.set_xlabel('Number of threads')
    ax.set_ylabel('Time in seconds')
    ax.set_xticks(x)
    ax.grid()
    ax.plot(x, y, 'ok')
    fig.savefig(f'{task}_time.png')

  def plot_acceleration(task, data):
    x  = numpy.empty((0,))
    y  = numpy.empty((0,))
    for k, v in data.items():
      if None in v:
        continue
      x = numpy.append(x, float(k))
      y = numpy.append(y, simple / (sum(v) / len(v)))

    fig, ax = plt.subplots(figsize=(16, 10))
    ax.set_title(f'Acceleration for {task}')
    ax.set_xlabel('Number of threads')
    ax.set_ylabel('Acceleration in seconds')
    ax.set_xticks(x)
    ax.grid()
    ax.plot(x, y, 'ok')
    fig.savefig(f'{task}_acceleration.png')

  simple = sum(sampling['simple']) / len(sampling['simple'])
  if not skip_openmp:
    data = sampling['openmp']
    plot_time(f'{task_name}_OPENMP', data)
    plot_acceleration(f'{task_name}_OPENMP', data)

  if not skip_mpi:
    data = sampling['mpi']
    plot_time(f'{task_name}_MPI', data)
    plot_acceleration(f'{task_name}_MPI', data)

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description='Simple script for sampling timing date for tasks execution') 
  parser.add_argument('--isize'      , type=int, default=10000,
                      help='Amount of rows in matrix (default is 10000)')
  parser.add_argument('--jsize'      , type=int, default=10000,
                      help='Amount of columns in matrix (default is 10000)')
  parser.add_argument('--threads'    , type=int, nargs='+', default=[i for i in range(1, 9)],
                      help=f'List of thread amounts for sampling (default is {[i for i in range(0, 9)]})')
  parser.add_argument('--samples'    , type=int, default=10,
                      help='Amount of samples for each observations (default is 10)')
  parser.add_argument('--build'      , type=str, default='build/',
                      help='Path to build directory')
  parser.add_argument('--task'       , type=str, default='TASK1',
                      help='Task to sample')
  parser.add_argument('--skip-mpi'   , action='store_true', default=False,
                      help='Flag to skip sampling of MPI')
  parser.add_argument('--skip-openmp', action='store_true', default=False,
                      help='Flag to skip sampling of OpenMP')
  parser.add_argument('--skip-plot'  , action='store_true', default=False,
                      help='Flag to skip creation of plot')
  parser.add_argument('--verbose'    , action='store_true', default=False,
                      help='Flag to use verbose mode')
  parser.add_argument('--overwrite'  , action='store_true', default=False,
                      help='Flag to overwrite existing sampling data instead of use it')

  args = parser.parse_args()

  sample_task(build=args.build, 
              isize=args.isize,
              jsize=args.jsize,
              threads=args.threads,
              samples=args.samples,
              skip_mpi=args.skip_mpi,
              skip_openmp=args.skip_openmp,
              v=args.verbose,
              overwrite=args.overwrite,
              task_name=args.task)
        
