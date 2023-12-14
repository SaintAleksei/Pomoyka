BUILD_DIR := build

SIMPLE    := TASK1_SIMPLE \
						 TASK2_SIMPLE \
             TASK3_SIMPLE

OPENMP    := TASK1_OPENMP \
             TASK3_OPENMP

MPI       := TASK1_MPI    \
						 TASK2_MPI		\

SRC       := task.c

CC             := gcc
CCFLAGS        := -Wall   \
                  -Wextra \
                  -Werror \
                  $(addprefix -D,$(OPTIONS))

OPENMP_CC      := $(CC)
OPENMP_CCFLAGS := $(CCFLAGS)  \
                  -fopenmp

MPI_CC         := mpicc
MPI_CCFLAGS    := $(CCFLAGS)

LDFLAGS        := -lm

.PHONY: all clean sample $(SIMPLE) $(OPENMP) $(MPI)

TASKS     := $(SIMPLE) $(OPENMP) $(MPI)
TASKS     := $(addsuffix .elf, $(TASKS))
TASKS     := $(addprefix $(BUILD_DIR), $(TASKS))

all: $(TASKS) 

$(TASKS): $(BUILD_DIR) $(SRC) $(SIMPLE) $(OPENMP) $(MPI)

$(BUILD_DIR):
	@mkdir -p $(abspath $@) 

$(SIMPLE): $(SRC)
	@$(CC) $(CCFLAGS)                     \
  -D$@ -D'RESULTS_FILE="$@.csv"'        \
  -o $(BUILD_DIR)/$@.elf $^ $(LDFLAGS)

$(OPENMP): $(SRC)
	@$(OPENMP_CC) $(OPENMP_CCFLAGS)       \
  -D$@ -D'RESULTS_FILE="$@.csv"'        \
  -o $(BUILD_DIR)/$@.elf $^ $(LDFLAGS)

$(MPI): $(SRC)
	@$(MPI_CC) $(MPI_CCFLAGS)             \
  -D$@ -D'RESULTS_FILE="$@.csv"'        \
  -o $(BUILD_DIR)/$@.elf $^ $(LDFLAGS)

clean:
	@rm -rf build/

