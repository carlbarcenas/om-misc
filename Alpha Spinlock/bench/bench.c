/*=============================================================================
#
# Author: Zhengyu He (zhengyu.he@gatech.edu)
# School of Electrical & Computer Engineering
# Georgia Institute of Technology
#
# Last modified: 2010-03-03 15:20
#
# Filename: bench.c
#
# Description: 
#
=============================================================================*/
#include "timer.h"
#include "lock.h"
#include <stdio.h>

int num_threads;
long *array;



void *worker(void *v)
{
	long t = (long)v;
	int i, j;
	 
	for (i = 0; i < ARRAY_SIZE; i++) {
		for (j = 0; j < ITERATION/num_threads; j++) {
			LOCK
			array[i] += t;
			UNLOCK
		}
	}
	pthread_exit(NULL);
}

int main(int argc, char **argv)
{
	long t;
	TIMER_T start, stop;
	pthread_t *threads;

	if (argc != 2) {
		fprintf(stderr, "%s num_threads \n", argv[0]);
		exit(1);
	}
	num_threads = atoi(argv[1]);

	INIT // initilization stage details in lock.h

	array = (long *)calloc(ARRAY_SIZE, sizeof(long));

	printf("Start ...");
	if ((threads =
	     (pthread_t *) malloc(num_threads * sizeof(pthread_t))) == NULL) {
		fprintf(stderr, "Error allocating threads \n");
		exit(1);
	}

	TIMER_READ(start);
	for (t = 0; t < num_threads; t++) {
		if (pthread_create(&threads[t], NULL, worker, (void *)t) != 0) {
			fprintf(stderr, "Error creating thread\n");
			exit(1);
		}

	}

	for (t = 0; t < num_threads; t++) {
		if (pthread_join(threads[t], NULL) != 0) {
			fprintf(stderr, "Error waiting for thread completion\n");
			exit(1);
		}
	}
	TIMER_READ(stop);
	printf("Done\n");

	printf("Checking ...");
	long result = (num_threads - 1) * ITERATION/2;

	for (t = 0; t < ARRAY_SIZE; t++) {
		if (array[t] != result) {
			fprintf(stderr, " (array[%ld]=%ld not %ld) Result is wrong, aborting ...\n", t, array[t], result);
			exit(1);
		}
	}
	printf("Passed\n");
	printf("\ntime cost: \t %f \n", TIMER_DIFF_SECONDS(start, stop));

	return 0;
}
