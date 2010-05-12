/*=============================================================================
#
# Author: Brian Ouellette (gth677b@mail.gatech.edu)
# Modified from: Zhengyu He (zhengyu.he@gatech.edu)
# School of Electrical & Computer Engineering
# Georgia Institute of Technology
#
# Last modified: 2010-04-16 11:55AM
#
# Filename: lock.h
#
# Description: Implementation of Anderson's Array Based Queue lock in Alpha ASM 
#
=============================================================================*/
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include "size.h"

#define INIT    init(); 
#define LOCK    unsigned int mine = my_spin_lock(&mutex);
#define UNLOCK 	my_spin_unlock(&mutex, mine);

extern long *array;
extern int num_threads;

volatile struct _mutex {
  // Cache line == 64 bytes == 16*4 byte integers
  // We'll only use the first field to index it to always be on a different cache line
  int slots[16][16];
  int next;
} mutex;

int init()
{
  int i;
  // Put 0 into lock slots 1-15
  for(i = 1; i < 16; i++) mutex.slots[i][0] = 0;
  // First lock is valid so put 1
  mutex.slots[0][0] = 1;
  mutex.next = 0;
  return 0;
}

int my_spin_unlock (volatile struct _mutex *lock, unsigned int mine)
{
  // Modulo not part of ISA so x % 16 == (x << 60) >> 60 == x & 15

  /* Debug Code
  printf("R:Mine: %i\n", mine);
  printf("R:test: %p\n", (&(lock->slots[0][0])+(mine)*16*4));
  printf("R:test: %i\n", *(&(lock->slots[0][0])+(mine)*16*4));
  printf("R:My slot: %i\n", lock->slots[mine][0]);
  */

  // Pseudocode:
  // mine = mine + 1
  // mine = mine & 15 (implementation of %16)
  // tmp = &base
  // tmp2 = mine << 4 (mine*16)
  // tmp = tmp2*4 + tmp (mine*16*4 + &base, indexing slots)
  // tmp2 = 0 + 1
  // tmp2->tmp

  unsigned int tmp, tmp2;
  asm volatile
    ("addl   %[mine],1,%[mine]\n"
     "and    %[mine],15,%[mine]\n"
     "lda    %[tmp],%[base]\n"
     "sll    %[mine],4,%[tmp2]\n"
     "s4addq %[tmp2],%[tmp],%[tmp]\n"
     "addl   $31,1,%[tmp2]\n"
     "stl    %[tmp2],0(%[tmp])\n"
     : [mine] "=r" (mine), [base] "=m" (lock->slots[0][0]), [tmp] "=r" (tmp), [tmp2] "=r" (tmp2)
     : "m" (lock->slots[0][0]), "0" (mine)
     : "memory");

  /* Debug Code
  printf("Out\n");
  printf("R:Next slot: %i\n", lock->slots[mine][0]);
  printf("R:Next addr: %x\n", tmp);
  printf("R:Next real: %p\n", &(lock->slots[mine][0]));
  printf("R:Mine after: %i\n", mine);
  */
  
  return 0;
}
  
int my_spin_lock (volatile struct _mutex *lock)
{
  // Runs on bus based 16 processor MESI system (no directory)
  // LDL_L = Load Sign-Extended Longword Locked (Longword == int/4 bytes)
  // BLBS  = Branch if Register Low Bit Is Set
  // OR    = Logical Or
  // STL_C = Store Longword from Register to Memory Conditional
  // BEQ   = Branch if Register Equal to Zero
  //
  // ORIGINAL SPINLOCK ALGORITHM
  // 1: ll lock->tmp
  //    goto 2 if tmp = 1 (lock taken)
  //    set last bit to 1
  //    sc tmp->lock
  //    goto 2 if tmp = 0 (sc failed)
  //    memory barrier
  //    return
  //
  // 2: load lock->tmp
  //    goto 2 if tmp = 1 (lock still taken)
  //    goto 1
  //    
  // ORIGINAL SPINLOCK CODE
  /* asm volatile
    ("1:        ldl_l   %0,%1\n"
     "          blbs    %0,2f\n"
     "          or      %0,1,%0\n"
     "          stl_c   %0,%1\n"
     "          beq     %0,2f\n"
     "          mb\n"
     ".subsection 2\n"
     "2:        ldl     %0,%1\n"
     "          blbs    %0,2b\n"
     "          br      1b\n"
     ".previous"
     : "=r" (tmp), "=m" (*lock)
     : "m" (*lock));*/

  // Fetch-And-Add Implementation from "atomic.h"
  // 1: ll counter->tmp
  //    result = tmp + i
  //    tmp = tmp + i
  //    sc tmp->counter
  //    goto 2 if tmp = 0 (sc failed)
  //    return
  //
  // 2: goto 1
  /*static inline int atomic_add_return(int i, atomic_t *v)
    {
      long temp, result;
      smp_mb();
      __asm__ __volatile__(
         "1: ldl_l %0,%1\n"
         " addl %0,%3,%2\n"
         " addl %0,%3,%0\n"
         " stl_c %0,%1\n"
         " beq %0,2f\n"
         ".subsection 2\n"
         "2: br 1b\n"
         ".previous"
         :"=&r" (temp), "=m" (v->counter), "=&r" (result)
         :"Ir" (i), "m" (v->counter) : "memory");
         smp_mb();
       return result;
    }*/

  // My Implementation Pseudocode
  // 1: ll lock.next->mine
  //    tmp = mine + 1
  //    sc tmp->lock.next
  //    goto 1 if failed
  //    tmp = 1 if (mine < 16)
  //    if tmp != 0 goto 3
  // 2: ll lock.next->tmp
  //    tmp = tmp - 16
  //    sc tmp->lock.next
  //    goto 2 if failed
  // 3: discard all but first 4 bits of mine 
  // 4: tmp = &lock->slots
  //    tmp2 = mine*16
  //    tmp = tmp2*4 + tmp
  // 5: tmp2 = {tmp}
  //    if tmp2 == 0 goto 5
  //    store 0->(lock->slots[mine])

  //printf("A:Lock->next before: %i\n", lock->next);

  unsigned int mine, tmp, tmp2;
  asm volatile
    ("1:  ldl_l  %[mine],%[next]\n"
     "    addl   %[mine],1,%[tmp]\n"
     "    stl_c  %[tmp],%[next]\n"
     "    beq    %[tmp],1b\n"
     "    cmpult %[mine],16,%[tmp]\n"
     "    bne    %[tmp],3f\n"
     "2:  ldl_l  %[tmp],%[next]\n"
     "    subl   %[tmp],16,%[tmp]\n"
     "    stl_c  %[tmp],%[next]\n"
     "    beq    %[tmp],2b\n"
     "3:  and    %[mine],15,%[mine]\n"    
     "4:  lda    %[tmp],%[base]\n"
     "    sll    %[mine],4,%[tmp2]\n"
     "    s4addq %[tmp2],%[tmp],%[tmp]\n"
     "5:  ldl    %[tmp2],0(%[tmp])\n"
     "    beq    %[tmp2],5b\n"
     "    stl    $31,0(%[tmp])\n"
     : [mine] "=r" (mine), [next] "=m" (lock->next), [base] "=m" (lock->slots[0][0]), [tmp] "=r" (tmp), [tmp2] "=r" (tmp2)
     : "m" (lock->next), "m" (lock->slots[0][0])
     : "memory");

  /* Debug Code
  printf("A:Lock->next after: %i\n", lock->next);
  printf("A:Mine: %i\n", mine);
  printf("A:Lock->mine: %i\n", lock->slots[mine][0]);
  printf("A:Lock->mine+1: %i\n", lock->slots[mine+1][0]);
  //printf("tmp:  0x%x\n", tmp);
  //printf("add:  %p\n", &(lock->slots[0]));
  */

  return mine;
}
