/* Brian Ouellette
   Produced independently aside from:
   http://en.wikipedia.org/wiki/Malloc
   http://en.wikipedia.org/wiki/Free_(programming)
   And some old class notes on how the malloc and free functions operate
   internally from ECE3035 with Scott and Linda Wills. */

#include <stdio.h>
#include <stdlib.h>

void * aligned_malloc(size_t, size_t);
void aligned_free(void * p);

void * test;
size_t malloc_size = 1171;
size_t malloc_alignment = 1024; /* For checking whether the pointer value was
				   correctly aligned.

				   128  = 0x80
				   256  = 0x100
				   512  = 0x200
				   1024 = 0x400 */

main()
{
	/* malloc adds a header before the pointer it returns to use in free
	   This header must not be modified and the original pointer must be
	   retrievable. So let's take a cue from malloc's book and add a
	   header of our own. This header is only 1 sizeof(void*) long and will
	   store the original address for use in aligned_free. It will be
	   located 1 sizeof(void*) before the pointer we return. This should
	   operate correctly regardless of the width of the memory address. */
	test = aligned_malloc(malloc_size, malloc_alignment);
	aligned_free(test);
}

void * aligned_malloc(size_t bytes, size_t alignment)
{
	/* We have to allocate additional space here to be sure that there will
	   be (size_t bytes) bytes AFTER the pointer we return and enough room
	   for our custom header BEFORE the pointer we return. The worst case
	   is that we recieve a malloc value less than sizeof(void*) BEFORE the
	   boundary. This won't leave enough space for our void pointer header
	   which is probably 4 or 8 bytes. Since we can't mung the malloc
	   header we have to return our pointer at the next alignment boundary.
	   In the most extreme corner case we'll have malloc return a pointer
	   with 1 byte less than the space we need to put our header in. In
	   this case we will need space for our allocated values (bytes) and
	   space to jump down to the next boundary AFTER the one we are right
	   in front of. alignment covers the boundary jump and sizeof(void*) 
	   covers the jump from malloc_original to the first boundary (from 
	   which we skip to the next). */ 
	void * malloc_original = malloc(bytes+alignment+sizeof(void*));

	/* This will return the original malloc pointer plus the difference
	   between the original pointer and the first alignment boundary. */
	size_t offset = alignment - ((size_t)malloc_original)%alignment;

	/* A little bit of handling of corner cases. This should guarantee 
	   that we have space for our header regardless of how close
	   to the boundary we were. If there isn't going to be room for our
	   header we skip to the next alignment boundary. */
	if(offset < sizeof(void*))
	{
		offset += alignment;
	}
	void * malloc_new = malloc_original + offset;

	/* Here I start getting tricky with pointers to do what I want. What
	   this line does is go up from the aligned_malloc pointer by one 
	   sizeof(void*) and stores the original malloc pointer. GCC doesn't let
	   you do pointer arithmetic directly on the void pointer so we cast it. */
	*(void **)((size_t)malloc_new-sizeof(void*)) = malloc_original;

	/* Just a little testing. The aligned version should be a higher memory
	   address than the original and the last couple bytes should
	   correspond to the table at the top of this file. */
	printf("Original: %p\nAligned:  %p\n", malloc_original, malloc_new);
	
	return malloc_new;
}

void aligned_free(void * p)
{
	/* And we pull the original malloc pointer out of our custom header. */
	printf("Freed:    %p\n", *(void **)((size_t)p-sizeof(void*)));

	free(*(void **)((size_t)p-sizeof(void*)));
}
