/*=============================================================================
#
# Author: Zhengyu He (zhengyu.he@gatech.edu)
# School of Electrical & Computer Engineering
# Georgia Institute of Technology
#
# Last modified: 2010-03-03 15:20
#
# Filename: timer.h
#
# Description: 
#
=============================================================================*/
#include <sys/time.h>


#define TIMER_T                         struct timeval

#define TIMER_READ(time)                gettimeofday(&(time), NULL)

#define TIMER_DIFF_SECONDS(start, stop) \
    (((double)(stop.tv_sec)  + (double)(stop.tv_usec / 1000000.0)) - \
     ((double)(start.tv_sec) + (double)(start.tv_usec / 1000000.0)))

#define GET_TIME(time) ((double)(time.tv_sec) + (double)(time.tv_usec / 1000000.0)) 

