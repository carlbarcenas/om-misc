################################################################################
#
# Build script for project
#
################################################################################

# Add source files here
EXECUTABLE	:= matrixmul
# Cuda source files (compiled with cudacc)
CUFILES		:= matrixmul.cu
# C/C++ source files (compiled with gcc / c++)
CCFILES		:= \
	matrixmul_gold.cpp

################################################################################
# Rules and targets

ROOTDIR = /usr/share/cuda-sdk/C/common
BINDIR  = .
include $(ROOTDIR)/common.mk
