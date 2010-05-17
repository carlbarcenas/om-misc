################################################################################
#
# Build script for project
#
################################################################################

# Add source files here
EXECUTABLE	:= 2Dconvolution 
# Cuda source files (compiled with cudacc)
CUFILES		:= 2Dconvolution.cu
# C/C++ source files (compiled with gcc / c++)
CCFILES		:= 2Dconvolution_gold.cpp 
CUDEPS		:= 2Dconvolution_kernel.cu
################################################################################
# Rules and targets

ROOTDIR = /usr/share/cuda-sdk/C/common
BINDIR = .
include $(ROOTDIR)/common.mk
