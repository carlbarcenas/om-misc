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

#ifndef _2DCONVOLUTION_KERNEL_H_
#define _2DCONVOLUTION_KERNEL_H_

#include <stdio.h>
#include "2Dconvolution.h"

// Matrix multiplication kernel thread specification
__global__ void ConvolutionKernel(float *M, float *N, float *P, int M_h, int M_w, int N_h, int N_w)
{
	// For 5x5 kernel
	// C(i,j) = sum (m = 0 to 4) { sum(n = 0 to 4) { A[m][n] * B[i+m-2][j+n-2] } }
	// where 0 <= i < B.height and 0 <= j < B.width
	int P_h = N_h;
	int P_w = N_w;

	__shared__ float Mds[KERNEL_SIZE][KERNEL_SIZE];
	__shared__ float Nds[BLOCK_SIZE+KERNEL_SIZE-1][BLOCK_SIZE+KERNEL_SIZE-1];

	int bx = blockIdx.x;
	int by = blockIdx.y;
	int tx = threadIdx.x;
	int ty = threadIdx.y;
	int row = by*BLOCK_SIZE + ty;
	int col = bx*BLOCK_SIZE + tx;
	int off = KERNEL_SIZE/2;

	float Pvalue = 0.0;

	// Don't do anything if we aren't operating on a valid pixel
	if(row < P_h && col < P_w)
	{
		// Load in the kernel. Must satisfy KERNEL_SIZE < BLOCK SIZE
		if(tx < KERNEL_SIZE && ty < KERNEL_SIZE)
			Mds[ty][tx] = M[ty*M_w + tx];
		
		// Load in the entire block to shared memory
		Nds[ty][tx] = N[row*N_w + col];
		// Still need KERNEL_SIZE/2 on either side for convolution
		if(tx == 0)
		{
			for(int i = 0; i <= off; i++)
				Nds[ty+off][off-i] = N[row*N_w + (col-i)];
		}
		else if(tx == BLOCK_SIZE-1)
		{
			for(int i = 0; i <= off; i++)
				Nds[ty+off][tx+off+i] = N[row*N_w + (col+i)];
		}
		if(ty == 0)
		{
			for(int i = 0; i <= off; i++)
				Nds[off-i][tx+off] = N[(row-i)*N_w + col];
		}
		else if(ty == BLOCK_SIZE-1)
		{
			for(int i = 0; i <= off; i++)
				Nds[ty+off+i][tx+off] = N[(row+i)*N_w + col];
		}
		__syncthreads();

		unsigned int m_b = (row < 2)? 2 - row : 0;
		unsigned int m_e = (row > (N_h - 3))? N_h - row + 2 : 5;
		unsigned int n_b = (col < 2)? 2 - col : 0;
		unsigned int n_e = (col > (N_w - 3))? N_w - col + 2 : 5;
		for(int m = m_b; m < m_e; m++)
		{
			for(int n = n_b; n < n_e; n++)
			{
				Pvalue += Mds[m][n]*N[(m+row-2)*N_w + n+col-2];
			}
		}
		P[row*P_w + col] = Pvalue;
	}
}

#endif // #ifndef _2DCONVOLUTION_KERNEL_H_
