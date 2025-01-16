EXEC = sobel_OMP

SRC = main.c

CC = gcc
CFLAGS = -fopenmp -Wall -O2

all: $(EXEC)

$(EXEC): $(SRC)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(EXEC)
