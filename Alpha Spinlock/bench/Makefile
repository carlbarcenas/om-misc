# Use this makefile on a real Alpha computer


CC =gcc

FLAG = -O0 -Wall -pthread  -static

all:bench

bench: bench.o  
	$(CC) $(FLAG) $^ -o $@ 

bench.o: bench.c
	$(CC) $(FLAG) -c $< -o $@



clean:
	rm *.o bench  -rf
