#ifndef _2DCONVOLUTION_KERNEL_H_
#define _2DCONVOLUTION_KERNEL_H_

#include <stdio.h>
#include "2Dconvolution.h"

#define N_SIZE BLOCK_SIZE+KERNEL_SIZE-1
#define OFF KERNEL_SIZE/2

// Matrix multiplication kernel thread specification
__global__ void ConvolutionKernel(float *M, float *N, float *P, int M_h, int M_w, int N_h, int N_w)
{
	// For 5x5 kernel
	// C(i,j) = sum (m = 0 to 4) { sum(n = 0 to 4) { A[m][n] * B[i+m-2][j+n-2] } }
	// where 0 <= i < B.height and 0 <= j < B.width
	int P_h = N_h;
	int P_w = N_w;

	__shared__ float Mds[KERNEL_SIZE][KERNEL_SIZE];
	__shared__ float Nds[N_SIZE][N_SIZE];

	int bx = blockIdx.x;
	int by = blockIdx.y;
	int tx = threadIdx.x;
	int ty = threadIdx.y;
	int row = by*BLOCK_SIZE + ty;
	int col = bx*BLOCK_SIZE + tx;

	float Pvalue = 0.0;

	// Load in the kernel using a tiled approach
	for(int i = 0; i <= KERNEL_SIZE/BLOCK_SIZE; i++)
	{
		for(int j = 0; j <= KERNEL_SIZE/BLOCK_SIZE; j++)
		{
			// Check that we are loading an address inside the kernel and then load it into shared memory
			if(tx+i*BLOCK_SIZE < KERNEL_SIZE &&
			   ty+j*BLOCK_SIZE < KERNEL_SIZE)
			{
				Mds[ty+j*BLOCK_SIZE][tx+i*BLOCK_SIZE] = M[(ty+j*BLOCK_SIZE)*M_w + tx+i*BLOCK_SIZE];
			}
		}
	}

	// Load in KERNEL_SIZE/2 around the block using a tiled approach
	for(int i = 1; i <= (KERNEL_SIZE/2)/BLOCK_SIZE; i++)
	{
		for(int j = 1; j <= (KERNEL_SIZE/2)/BLOCK_SIZE; j++)
		{
			int xds = tx+i*BLOCK_SIZE+OFF;
			int yds = ty+j*BLOCK_SIZE+OFF;
			// First check that the index we want is a valid element of N, then check that it is needed
			// It will be needed if it fits into our Nds which is sized for BLOCK_SIZE and KERNEL_SIZE/2 on either side
			if(xds < N_SIZE && yds < N_SIZE)
			{
				int x = col+i*BLOCK_SIZE;
				int y = row+j*BLOCK_SIZE;
				if(x < N_w && y < N_h)
				{
					// Load in the index
					Nds[yds][xds] = N[y*N_w + x];
				}
				else
				{
					Nds[yds][xds] = 0.0;
				}
			}
		}
	}

	// Don't do anything if we aren't operating on a valid pixel
	if(row < P_h && col < P_w)
	{
		// Load in entire block to shared memory
		Nds[ty+OFF][tx+OFF] = N[row*N_w + col];
		// Ensure all threads have access to the shared memory loads
		__syncthreads();

		unsigned int m_b = (row < OFF)? OFF - row : 0;
		unsigned int m_e = (row >= (N_h - OFF))? N_h - row + OFF : KERNEL_SIZE;
		unsigned int n_b = (col < OFF)? OFF - col : 0;
		unsigned int n_e = (col >= (N_w - OFF))? N_w - col + OFF : KERNEL_SIZE;
		for(int m = m_b; m < m_e; m++)
		{
			for(int n = n_b; n < n_e; n++)
			{
				Pvalue += Mds[m][n]*N[(m+row-OFF)*N_w + n+col-OFF];
				//Pvalue += Mds[m][n]*Nds[m+ty][n+tx];
			}
		}
		P[row*P_w + col] = Pvalue;
	}
}

#endif // #ifndef _2DCONVOLUTION_KERNEL_H_
