EXEC = sobel_OMP

SRC = main.c ../Tools/tools.c
OBJ = main.o ../Tools/tools.o

CC = gcc
CFLAGS = -fopenmp -Wall -O3
INCLUDES = -I../Tools
LIBS = -lpng

all: $(EXEC)

$(EXEC): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

main.o: main.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

../Tools/tools.o: ../Tools/tools.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -f $(EXEC) $(OBJ)
