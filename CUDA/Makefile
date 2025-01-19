EXEC = sobel_CUDA

SRC = main.cu
OBJ = main.o

CC = gcc
CXX = g++
NVCC = nvcc
CFLAGS = -Wall -O3
CXXFLAGS = -O3
INCLUDES = -I../Tools
LIBS = -lpng -lm

CUDA_FLAGS = -arch=sm_61
CUDA_LIBS = -lcuda -lcudart

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS) $(CUDA_LIBS)

main.o: main.cu
	$(NVCC) $(CUDA_FLAGS) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -f $(EXEC) $(OBJ)
