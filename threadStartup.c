// Compile with gcc -pthread -o threadStartup threadStartup.c
#include <sys/time.h>
#include <stdio.h>
#include <pthread.h>
#include <sched.h>

void *test_function();

main(int argc, char *argv[])
{
	int num_threads = 100000;
	float proc_GHz = 1.6;

	// Array of thread IDs
	pthread_t threads[num_threads]; 

	struct timeval t1, t2;
	double elapsed;

	int i;
	gettimeofday(&t1, NULL);
	for(i = 0; i < num_threads; i++)
	{
		pthread_create(&threads[i], NULL, test_function, (void *)i);
	}
	gettimeofday(&t2, NULL);
	elapsed = ((t2.tv_sec + t2.tv_usec/1000000.0) - (t1.tv_sec + t1.tv_usec/1000000.0));
	printf("Elapsed Time: %f\n", elapsed);
	printf("Avg Startup (cycles): %f\n", elapsed / (float)num_threads * proc_GHz * 1000000000.0);
}

void *test_function(void *i)
{
}
