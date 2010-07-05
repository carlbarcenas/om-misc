/*
 * Copyright 1993-2006 NVIDIA Corporation.  All rights reserved.
 *
 * NOTICE TO USER:   
 *
 * This source code is subject to NVIDIA ownership rights under U.S. and 
 * international Copyright laws.  
 *
 * This software and the information contained herein is PROPRIETARY and 
 * CONFIDENTIAL to NVIDIA and is being provided under the terms and 
 * conditions of a Non-Disclosure Agreement.  Any reproduction or 
 * disclosure to any third party without the express written consent of 
 * NVIDIA is prohibited.     
 *
 * NVIDIA MAKES NO REPRESENTATION ABOUT THE SUITABILITY OF THIS SOURCE 
 * CODE FOR ANY PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR 
 * IMPLIED WARRANTY OF ANY KIND.  NVIDIA DISCLAIMS ALL WARRANTIES WITH 
 * REGARD TO THIS SOURCE CODE, INCLUDING ALL IMPLIED WARRANTIES OF 
 * MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE.   
 * IN NO EVENT SHALL NVIDIA BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL, 
 * OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS 
 * OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE 
 * OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE 
 * OR PERFORMANCE OF THIS SOURCE CODE.  
 *
 * U.S. Government End Users.  This source code is a "commercial item" as 
 * that term is defined at 48 C.F.R. 2.101 (OCT 1995), consisting  of 
 * "commercial computer software" and "commercial computer software 
 * documentation" as such terms are used in 48 C.F.R. 12.212 (SEPT 1995) 
 * and is provided to the U.S. Government only as a commercial end item.  
 * Consistent with 48 C.F.R.12.212 and 48 C.F.R. 227.7202-1 through 
 * 227.7202-4 (JUNE 1995), all U.S. Government End Users acquire the 
 * source code with only those rights set forth herein.
 */

/* Matrix multiplication: C = A * B.
 * Device code.
 */

#ifndef _MATRIXMUL_KERNEL_H_
#define _MATRIXMUL_KERNEL_H_

#include <stdio.h>
#include "matrixmul.h"

// Tile size has to be less than sqrt(512) == 23 since we can only have 512 threads in a block
#define TILE 16 

////////////////////////////////////////////////////////////////////////////////
//! Simple test kernel for device functionality
//! @param g_idata  input data in global memory
//! @param g_odata  output data in global memory
////////////////////////////////////////////////////////////////////////////////
// Matrix multiplication kernel thread specification
__global__ void MatrixMulKernel(float* M, float* N, float* P, int M_h, int M_w, int N_w)
{
	int N_h = M_w;
	int P_h = M_h;
	int P_w = N_w;
	 
	__shared__ float Mds[TILE][TILE];
	__shared__ float Nds[TILE][TILE];

	int bx = blockIdx.x;
	int by = blockIdx.y;
	int tx = threadIdx.x;
	int ty = threadIdx.y;
	int row = by*TILE + ty;
	int col = bx*TILE + tx;

	float Pvalue = 0.0;
	
	// For each tile
	int i;
	for(i = 0; i < M_w - TILE; i += TILE)
	{
		// Help load M and N tiles into shared memory
		Mds[ty][tx] = M[row*M_w + (i+tx)];
		Nds[ty][tx] = N[(i+ty)*N_w + col];
		// Ensure that every element is loaded
		__syncthreads();
		// Calculate this threads value
		for(int k = 0; k < TILE; ++k)
			Pvalue += Mds[ty][k]*Nds[k][tx];
		// Sync here to make sure that everyone is done using Mds and Nds
		__syncthreads();
	}
	
	// We still have to clean up the edges in case the matrix isn't aligned to tile size
	// Load in the value from M into the tile (or 0 if we are outside the matrix bounds)
	int index = row*M_w + (i+tx);
	if(index < M_h*M_w)
		Mds[ty][tx] = M[index];
	else
		Mds[ty][tx] = 0.0;

	// Load in the value from N into the tile (or 0 if we are outside the matrix bounds)
	index = (i+ty)*N_w + col;
	if(index < N_h*N_w)
		Nds[ty][tx] = N[index];
	else
		Nds[ty][tx] = 0.0;
	
	// Ensure that every element is loaded
	__syncthreads();
	for(int k = 0; k < TILE; ++k)
		Pvalue += Mds[ty][k]*Nds[k][tx];
		
	// Copy the element we calculated back if it is a valid element of P
	if(row < P_h && col < P_w)
		P[row*P_w + col] = Pvalue;
}

#endif // #ifndef _MATRIXMUL_KERNEL_H_
