################################################################################
#
# Build script for project
#
################################################################################

# Add source files here
EXECUTABLE	:= scan_largearray
# Cuda source files (compiled with cudacc)
CUFILES		:= scan_largearray.cu 
# C/C++ source files (compiled with gcc / c++)
CCFILES		:= \
	scan_gold.cpp \


################################################################################
# Rules and targets

ROOTDIR = /usr/share/cuda-sdk/C/common
BINDIR = .
include $(ROOTDIR)/common.mk
