ECE498 AL Machine Problem 5 / KLA Tencor Challenge
Histogramming

Introduction:
-------------
Histogramming is a common processing technique used to determine the frequency
of occurences in the input of a certain category, also known as a bin. The simplest
example for the use of histogramming is determining a grade distribution from a
set of grades.

Example:

Grades: 0, 1, 1, 4, 0, 2, 5, 5, 5

The above grades ranging from 0 to 5 result in the following 6-bin histogram

Histogram: 2, 2, 1, 0, 1, 3

The zipped file /home/ac/stratton/498_admin/mps/mp5-histogram.tgz contains 
a directory with the following files:
--------------------------------------------
   *) readme.txt:              This file

   *) Makefile:                The makefile to compile you code.

   *) util.h:                  Header file with some utility macros and function prototypes.
   *) util.c:                  Source file with some utility functions.

   *) ref_2dhisto.h:           Header file for the reference kernel.
   *) ref_2dhisto.cpp:         Source file for the scalar reference implementation of the kernel.

   *) test_harness.cpp:        Source file with main() method that has a sample call to the kernel.
                               The test_harness code generates two output files (gold.html, and
                               kernel.html).  These files show the resulting histogram in images form.
                               These files are unnecessary, but may help in understanding the task.

   *) opt_2dhisto.h:           Header file for the parallel kernel. (currently empty)
   *) opt_2dhisto.cu:          Source file for the parallel implementation of the kernel. (Currently empty)

Your Task:
----------
The task is to implement an optimized function:

   int opt_2dhisto(uint32_t *input[],
                   size_t height,
                   size_t width,
                   uint8_t bins[HISTO_HEIGHT][HISTO_WIDTH]);

The optimization is expected to use CUDA (run on NVIDIA GPUs).

ref_2dhisto() constructs a 2D histogram (or joint density distribution)
from the passed in input bin ids in 'input'.

   *) 'input' is a 2D array of histogram bins.  These will all be
      valid bins, so no range checking is required.
   *) 'height' and 'width' are the height and width of the input.
   *) 'bins' is the histogram.  HISTO_HEIGHT and HISTO_WIDTH are
      the dimensions of the histogram (and are 4096 and 256 respectively ...
      resulting in a 1M-bin histogram).

The optimized version of the function should be named 'opt_2dhisto'

Some assumptions/constraints:
   ( 1) The 'input' data consists of index values into the 'bins'
   ( 2) The 'input' bins are *NOT* uniformly distributed.  This non-uniformy is a large
        portion of what makes this interesting for GPUs.
   ( 3) For each bin in the histogram, once the count reaches 255, then
        no further incrementing should occur.  This is sometimes called a
        "saturating counter".  DO NOT "ROLL-OVER".

You should only edit the following files: opt_2dhisto.h opt_2dhisto.cu test_harness.cpp
Do NOT modify any other files. Furthermore, only modify test_harness.cpp where instructed
to do so (view comments in file). You should only measure the runtime of the kernel itself,
so any GPU allocations and data transfers should be done outside the function 'opt_2dhisto'.
The arguments to the function 'opt_2dhisto' have been intentionally left out for you to
specify based on your implementation.

You may not use anyone else's histogramming solution, however, you are allowed to use 
third-party implementations of primitive operations in your solution. If you choose to do so,
it is your responsibility to include these libraries in the tar file you submit and modify 
the Makefile so that your code compiles and runs. You must also mention any use of third-party 
libraries in your report. Failure to do so may be considered plagiarism. If you are uncertain 
whether a function is considered a primitive operation or not, please inquire about it on the 
web board.

To Run:
-------
The provided Makefile will generate an executable in the usual SDK binary
directory with the name 'histo'.  There are two modes of operation for the application.

    No arguments: The application will use a default seed value for the random number 
    generator when creating the input image.

    One argument: The application will use the seed value provided as a command-line 
    argument. When measuring the performance of your application, we will use this mode with a
    set of different seed values.

When run, the application will report timing information for the sequential code followed by 
the timing information of the parallel implementation. It will also compare the two outputs 
and print "Test PASSED" if the outputs are identical, and "Test FAILED" otherwise. You can 
also use any internet browser to render the html outputs generated by the program to get an 
understanding of what's going on.

The base code provided to you should compile and run without errors or warning, but will fail
the comparison.

Submitting the MP:
------------------
To submit your solution, execute the mp5submit.sh script with your netid and a .tgz file
containing your entire submission, including the file containing your report.

The .tgz file should contain the mp5-histogram folder provided, with all the changes and
additions you have made to the source code.  In addition, provide a text file of your report.

Your report should simply contain a journal of all optimizations you tried, including those that
ultimately were abandonded or worsened performance.  Your report should have an entry for every
optimization tried, and each entry should note:
   1) the changes you made for the optimization
   2) any difficulties with completing the optimization correctly
   3) the amount of time spent on it (even if it was abandoned before working)
   4) if finished and working, the speedup of the code after the optimization was applied

Grading:
--------
Your submission will be graded on the following parameters.

Demo/knowledge: 25%
   - 15% : Produces correct result output files for our test inputs.
   - 10%+ = 10% * (Sequential runtime / Your runtime)
       (Yes, you can get over 100% on this assignment)

Functionality:  40%
   - This is the qualitative portion of your grade. For this
     portion, we will grade the thoughtfulness you put into speeding
     up the application. We realize that this application is hard to
     speed up, so the grade for this section does not depend on the
     timing you achieved.

Report: 35%
   - Complete and accurate journal.  We will at least check for discrepencies,
     optimizations that you did but didn't report, etc.
