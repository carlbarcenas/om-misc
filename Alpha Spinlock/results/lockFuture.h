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
#define LOCK    unsigned int mine = my_spin_lock(&mutex, i%16);
#define UNLOCK 	my_spin_unlock(&mutex, mine, i%16);

extern long *array;
extern int num_threads;

volatile struct _mutex {
  // Cache line == 64 bytes == 16*4 byte integers
  // We'll only use the first field to index it to always be on a different cache line
  int slots[16][16];
  int next[16];
} mutex;

int init()
{
  int i, j;
  // Put 0 into lock slots 1-15
  for(i = 1; i < 16; i++)
    for(j = 0; j < 16; j++)
      mutex.slots[i][j] = 0;
  // First lock is valid so put 1
  for(j = 0; j < 16; j++)
  {
    mutex.slots[0][j] = 1;
    mutex.next[j] = 0;
  }
  return 0;
}

int my_spin_unlock (volatile struct _mutex *lock, unsigned int mine, unsigned int lockNum)
{
  unsigned int tmp, tmp2;
  asm volatile
    ("addl   %[mine],1,%[mine]\n"
     "and    %[mine],15,%[mine]\n"
     "lda    %[tmp],%[base]\n"
     "sll    %[mine],4,%[tmp2]\n"
     "s4addq %[tmp2],%[tmp],%[tmp]\n"
     "addl   $31,1,%[tmp2]\n"
     "stl    %[tmp2],0(%[tmp])\n"
     : [mine] "=r" (mine), [base] "=m" (lock->slots[0][lockNum]), [tmp] "=r" (tmp), [tmp2] "=r" (tmp2)
     : "m" (lock->slots[0][0]), "0" (mine)
     : "memory");  
  return 0;
}
  
int my_spin_lock (volatile struct _mutex *lock, unsigned int lockNum)
{
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
     : [mine] "=r" (mine), [next] "=m" (lock->next[lockNum]), [base] "=m" (lock->slots[0][lockNum]), [tmp] "=r" (tmp), [tmp2] "=r" (tmp2)
     : "m" (lock->next[lockNum]), "m" (lock->slots[0][lockNum])
     : "memory");
  return mine;
}
