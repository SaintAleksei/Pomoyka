#!/usr/bin/bash

if [ -z "$TEST_ISIZE" ];
then
  TEST_ISIZE=1000
fi

if [ -z "$TEST_JSIZE" ];
then
  TEST_JSIZE=1000
fi


# $1 - task
test_task_openmp() 
{
  rm -f $1_SIMPLE.elf

  ./build/$1_SIMPLE.elf $TEST_ISIZE $TEST_JSIZE 1>/dev/null 2>/dev/null

  for i in $2;
  do
    echo -n "[INF] TEST $1_OPENMP with $i threads..."  

    rm -f $1_OPENMPqelf

    ./build/$1_OPENMP.elf $TEST_ISIZE $TEST_JSIZE $i 1>/dev/null 2>/dev/null
    if [ ! $? -eq 0 ] || [ ! -f "$1_OPENMP.csv" ]; 
    then
      echo -e " \033[31mFAILED\033[0m"
      return 1
    fi

    if [ ! -z "$(diff $1_SIMPLE.csv $1_OPENMP.csv)"];
    then
      echo -e " \033[31mFAILED\033[0m"
      return 1
    fi

    echo -e " \033[32mPASSED\033[0m"
  done

  return 0
}

# $1 - task
test_task_mpi()
{
  rm -f $1_SIMPLE.csv

  ./build/$1_SIMPLE.elf $TEST_ISIZE $TEST_JSIZE 1>/dev/null 2>/dev/null

  for i in $2;
  do
    echo -n "[INF] TEST $1_MPI    with $i threads..."  

    rm -f $1_MPI.csv

    mpirun -np $i ./build/$1_MPI.elf $TEST_ISIZE $TEST_JSIZE 1>/dev/null 2>/dev/null
    if [ ! $? -eq 0 ] || [ ! -f "$1_MPI.csv" ]; 
    then
      echo -e " \033[31mFAILED\033[0m"
      return 1
    fi

    if [ ! -z "$(diff $1_SIMPLE.csv $1_MPI.csv)"];
    then
      echo -e " \033[31mFAILED\033[0m"
      return 1
    fi

    echo -e " \033[32mPASSED\033[0m"
  done

  return 0
}

make clean && make OPTIONS=SAVE_RESULTS

test_task_openmp TASK1 "1 2 3 4"
test_task_mpi    TASK1 "1 2 3 4"
test_task_mpi    TASK2 "3"
test_task_openmp TASK3 "1 2 3 4"

make clean && rm *.csv
