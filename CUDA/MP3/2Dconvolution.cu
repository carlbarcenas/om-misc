// includes, system
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

// includes, project
#include <cutil.h>

// includes, kernels
#include <2Dconvolution_kernel.cu>

////////////////////////////////////////////////////////////////////////////////
// declarations, forward

extern "C"
void computeGold(float*, const float*, const float*, unsigned int, unsigned int);

Matrix AllocateDeviceMatrix(const Matrix M);
Matrix AllocateMatrix(int height, int width, int init);
void CopyToDeviceMatrix(Matrix Mdevice, const Matrix Mhost);
void CopyFromDeviceMatrix(Matrix Mhost, const Matrix Mdevice);
int ReadFile(Matrix* M, char* file_name);
void WriteFile(Matrix M, char* file_name);
void FreeDeviceMatrix(Matrix* M);
void FreeMatrix(Matrix* M);

void ConvolutionOnDevice(const Matrix M, const Matrix N, Matrix P);


////////////////////////////////////////////////////////////////////////////////
// Program main
////////////////////////////////////////////////////////////////////////////////
int main(int argc, char** argv) {

	Matrix  M;
	Matrix  N;
	Matrix  P;
	
	srand(2012);
	
	if(argc != 5 && argc != 4) 
	{
		// Allocate and initialize the matrices
		M  = AllocateMatrix(KERNEL_SIZE, KERNEL_SIZE, 1);
		N  = AllocateMatrix((rand() % 1024) + 1, (rand() % 1024) + 1, 1);
		P  = AllocateMatrix(N.height, N.width, 0);
	}
	else
	{
		// Allocate and read in matrices from disk
		int* params = NULL; 
		unsigned int data_read = 0;
		cutReadFilei(argv[1], &params, &data_read, true);
		if(data_read != 2){
			printf("Error reading parameter file\n");
			cutFree(params);
			return 1;
		}

		M  = AllocateMatrix(KERNEL_SIZE, KERNEL_SIZE, 0);
		N  = AllocateMatrix(params[0], params[1], 0);		
		P  = AllocateMatrix(params[0], params[1], 0);
		cutFree(params);
		(void)ReadFile(&M, argv[2]);
		(void)ReadFile(&N, argv[3]);
	}

	// M * N on the device
    ConvolutionOnDevice(M, N, P);
    
    // compute the matrix multiplication on the CPU for comparison
    Matrix reference = AllocateMatrix(P.height, P.width, 0);
    computeGold(reference.elements, M.elements, N.elements, N.height, N.width);
        
    // in this case check if the result is equivalent to the expected soluion
    CUTBoolean res = cutComparefe(reference.elements, P.elements, P.width * P.height, 0.001f);
    printf("Test %s\n", (1 == res) ? "PASSED" : "FAILED");
    
    if(argc == 5)
    {
		WriteFile(P, argv[4]);
	}
	else if(argc == 2)
	{
	    WriteFile(P, argv[1]);
	}   

	// Free matrices
    FreeMatrix(&M);
    FreeMatrix(&N);
    FreeMatrix(&P);
	return 0;
}


////////////////////////////////////////////////////////////////////////////////
//! Run a simple test for CUDA
////////////////////////////////////////////////////////////////////////////////
void ConvolutionOnDevice(const Matrix M, const Matrix N, Matrix P)
{
	// M == kernel
	// N == image
	// P == convolved image, same size at N

	size_t Msize = M.width * M.height * sizeof(float);
	size_t Nsize = N.width * N.height * sizeof(float);
	size_t Psize = P.width * P.height * sizeof(float);

    // Load M and N to the device
	float *Md;
	float *Nd;
	cudaMalloc(&Md, Msize);
	cudaMemcpy(Md, M.elements, Msize, cudaMemcpyHostToDevice);
	cudaMalloc(&Nd, Nsize);
	cudaMemcpy(Nd, N.elements, Nsize, cudaMemcpyHostToDevice);

    // Allocate P on the device
	float *Pd;
	cudaMalloc(&Pd, Psize);
	cudaMemcpy(Pd, P.elements, Psize, cudaMemcpyHostToDevice);

    // Setup the execution configuration
	int width, height;

	width = P.width/BLOCK_SIZE;
	if(P.width%BLOCK_SIZE != 0)
		width++;
	
	height = P.height/BLOCK_SIZE;
	if(P.height%BLOCK_SIZE != 0)
		height++;

	dim3 dimGrid(width, height);
	dim3 dimBlock(BLOCK_SIZE, BLOCK_SIZE);
 
    // Launch the device computation threads!
	ConvolutionKernel<<<dimGrid, dimBlock>>>(Md, Nd, Pd, M.height, M.width, N.height, N.width);

    // Read P from the device
	cudaMemcpy(P.elements, Pd, Psize, cudaMemcpyDeviceToHost);

    // Free device matrices
	cudaFree(&Md);
	cudaFree(&Nd);
	cudaFree(&Pd);
}

// Allocate a device matrix of same size as M.
Matrix AllocateDeviceMatrix(const Matrix M)
{
    Matrix Mdevice = M;
    int size = M.width * M.height * sizeof(float);
    cudaMalloc((void**)&Mdevice.elements, size);
    return Mdevice;
}

// Allocate a device matrix of dimensions height*width
//	If init == 0, initialize to all zeroes.  
//	If init == 1, perform random initialization.
//  If init == 2, initialize matrix parameters, but do not allocate memory 
Matrix AllocateMatrix(int height, int width, int init)
{
    Matrix M;
    M.width = M.pitch = width;
    M.height = height;
    int size = M.width * M.height;
    M.elements = NULL;
    
    // don't allocate memory on option 2
    if(init == 2)
		return M;
		
	M.elements = (float*) malloc(size*sizeof(float));

	for(unsigned int i = 0; i < M.height * M.width; i++)
	{
		M.elements[i] = (init == 0) ? (0.0f) : (rand() / (float)RAND_MAX);
		if(rand() % 2)
			M.elements[i] = - M.elements[i];
	}
    return M;
}	

// Copy a host matrix to a device matrix.
void CopyToDeviceMatrix(Matrix Mdevice, const Matrix Mhost)
{
    int size = Mhost.width * Mhost.height * sizeof(float);
    Mdevice.height = Mhost.height;
    Mdevice.width = Mhost.width;
    Mdevice.pitch = Mhost.pitch;
    cudaMemcpy(Mdevice.elements, Mhost.elements, size, 
					cudaMemcpyHostToDevice);
}

// Copy a device matrix to a host matrix.
void CopyFromDeviceMatrix(Matrix Mhost, const Matrix Mdevice)
{
    int size = Mdevice.width * Mdevice.height * sizeof(float);
    cudaMemcpy(Mhost.elements, Mdevice.elements, size, 
					cudaMemcpyDeviceToHost);
}

// Free a device matrix.
void FreeDeviceMatrix(Matrix* M)
{
    cudaFree(M->elements);
    M->elements = NULL;
}

// Free a host Matrix
void FreeMatrix(Matrix* M)
{
    free(M->elements);
    M->elements = NULL;
}

// Read a 16x16 floating point matrix in from file
int ReadFile(Matrix* M, char* file_name)
{
	unsigned int data_read = M->height * M->width;
	cutReadFilef(file_name, &(M->elements), &data_read, true);
	return data_read;
}

// Write a 16x16 floating point matrix to file
void WriteFile(Matrix M, char* file_name)
{
    cutWriteFilef(file_name, M.elements, M.width*M.height,
                       0.0001f);
}
