#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <complex.h>
#include <stdbool.h>
#include <assert.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "../complex/icomplex.h"

/*
* iota.sparse library
* sparse arpack.standard from arpack for Lua 5.4
* Rodrigo A. Moreira <rodrigoams@gmail.com>
* 10 Jan 2019
* This code is hereby placed in the public domain.
*/

#define EIGSTYPE "complex arpack znaupd_()"
#define MYVERSION  EIGSTYPE " from ιlibrary  for " LUA_VERSION " / Jan 2019"

static int file_exists(const char *fname) {
	FILE *file;
	if ((file = fopen(fname, "r"))) {
        fclose(file);
        return 1;
    }
    return 0;
}

extern void znaupd_(int *ido,
char *bmat, int *n, char *which, int *nev, double *tol, double complex *resid, int *ncv, double complex *V, int *ldv, int *iparam, int *ipntr, double complex *workd, double complex *workl, int *lworkl, double *rwork, int *info);

extern void zneupd_(int *rvec, char *howmny, int *select, double complex *D, double complex *Z,int *ldz, double complex *sigma, double complex *workev,
char *bmat, int *n, char *which, int *nev, double *tol, double complex *resid, int *ncv, double complex *V, int *ldv, int *iparam, int *ipntr, double complex *workd, double complex *workl, int *lworkl, double *rwork, int *info);

static double * alloc_double(lua_State *L, size_t size) {
	double * vec = lua_newuserdata(L, size*sizeof(double));
	if (vec == NULL) luaL_error(L, "impossible to allocate %f MBytes of memory.", size*sizeof(double)/1000/1000);
	memset(vec, 0, size*sizeof(double));
	return vec;
}

static double complex * alloc_doublecomplex(lua_State *L, size_t size) {
	double complex * vec = lua_newuserdata(L, size*sizeof(double complex));
	if (vec == NULL) luaL_error(L, "impossible to allocate %f MBytes of memory.", size*sizeof(double)/1000/1000);
	memset(vec, 0, size*sizeof(double complex));
	return vec;
}

static void arpack_info (lua_State *L, int info) {
	switch (info) {
		case 0: break; //Normal exit.
		case 1: luaL_error(L, "Maximum number of iterations taken. All possible eigenvalues of OP has been found. IPARAM(5) returns the number of wanted converged Ritz values.\n"); break;
		case 2: break;
		case 3: luaL_error(L, "No shifts could be applied during a cycle of the Implicitly restarted Arnoldi iteration. One possibility is to increase the size of NCV relative to NEV.\n"); break;
		case  -1: luaL_error(L, "N must be positive."); break;
		case  -2: luaL_error(L, "NEV must be positive."); break;
		case  -3: luaL_error(L, "NCV-NEV >= 2 and less than or equal to N."); break;
		case -4: luaL_error(L, "The maximum number of Arnoldi update iterations must be greater than zero."); break;
		case  -5: luaL_error(L, "WHICH must be one of 'LM', 'SM', 'LR', 'SR', 'LI', 'SI'."); break;
		case  -6: luaL_error(L, "BMAT must be one of 'I' or 'G'."); break;
		case  -7: luaL_error(L, "Length of private work array is not sufficient."); break;
		case  -8: luaL_error(L, "Error return from LAPACK eigenvalue routine."); break;
		case  -9: luaL_error(L, "Starting vector is zero."); break;
		case  -10: luaL_error(L, "IPARAM(7) must be 1,2,3."); break;
		case  -11: luaL_error(L, "IPARAM(7) = 1 and BMAT = 'G' are incompatible."); break;
		case -12: luaL_error(L, "IPARAM(1) must be equal to 0 or 1. OR HOWMNY = 'S' not yet implemented."); break;
		case -13: luaL_error(L,"HOWMNY must be one of 'A' or 'P' if RVEC = .true."); break;
		case -14: luaL_error(L,"ZNAUPD did not find any eigenvalues to sufficient accuracy."); break;
		case -15: luaL_error(L,"ZNEUPD got a different count of the number of converged Ritz values than ZNAUPD got.  This indicates the user probably made an error in passing data from ZNAUPD to ZNEUPD or that the data was modified before entering ZNEUPD"); break;
		case -9999: luaL_error(L, "Could not build an Arnoldi factorization. User input error highly likely. Please check actual array dimensions and layout. IPARAM(5) returns the size of the current Arnoldi factorization."); break;
		default: luaL_error(L, "'arpack' error %d .  Verify the manual.", info);
	}
}

static void clean_table (lua_State *L, int arg) {
	luaL_checktype(L, arg, LUA_TTABLE);
	lua_pushnil(L); // first 'key' to prepare to lua_next()
	while (lua_next(L, arg) != 0) {
		lua_pop(L, 1); // value
		lua_pushvalue(L, -1); // key
		lua_pushnil(L);
		lua_rawset(L, arg);
	}
}

static void table2array(lua_State *L, int arg, int N, double complex * array) {
	luaL_checktype(L, arg, LUA_TTABLE);
	for (int k=0;k<N;k++) {
		lua_rawgeti(L, arg, k+1);
		array[k] = icheckcomplex(L,-1);
		lua_pop(L,1);
	}
}

static void array2table(lua_State *L, int arg, int N, double complex * array) {
	luaL_checktype(L, arg, LUA_TTABLE);
	for (int k=0;k<N;k++) {
		ipushcomplex(L, array[k]);
		lua_rawseti(L, arg, k+1);
	}
}

static int standard(lua_State *L) {
	int N = (int) luaL_checkinteger(L, 1); // Problem size
	int nev = (int) luaL_optinteger(L, 2, 15); // Number of eigenvalues of OP to be computed. 0 < NEV < N
	luaL_checktype(L, 3, LUA_TFUNCTION); // OP*X
	double tol = (lua_Number) luaL_optnumber(L, 4, 0.0); // Stopping criterion

	lua_createtable(L, N, 0);
	lua_insert(L, 1);
	clean_table(L, 1);

	printf("::ARPACK::\n");
	printf("|\tN:\t %10d\t|\n", N);
	printf("|\tNEV:\t %10d\t|\n",nev);

	/* ARPACK CONFIG */
	int ido = 0;  // Reverse communication flag first call
	char * bmat = "I";  // Standard eigenvalue problem A*x = lambda*x
	// N // dimension of the eigenproblem
	char * which = "SR"; //want the NEV eigenvalues of smallest real part.
	// nev; // Number of eigenvalues of OP to be computed. 0 < NEV < N-1.
	// tol; //Stopping criteria
	double complex * resid = alloc_doublecomplex(L, N);
	int ncv = 2*nev+1; printf("|\tNCV:\t %10d\t|\n",ncv);
	double complex * V = alloc_doublecomplex(L, ncv*N);
	int ldv = N;
	int iparam[11];
	iparam[0] = 1;	// Specifies the shift strategy (1->exact)
	iparam[1] = 0; // no longer referenced
	iparam[2] = N; //MXITER
	iparam[3] = 1;	// NB blocksize in recurrence. ARPACK mentions only 1 is supported currently
	iparam[4] = 0; //NCONV: number of "converged" Ritz values.
	iparam[5] = 0; // no longer refenrenced
	iparam[6] = 1; // Mode 1 -> A*x = lambda*x
	iparam[7] = 0;
	iparam[8] = 0;
	iparam[9] = 0;
	iparam[10] = 0;
	int ipntr[14];
	double complex * workd = alloc_doublecomplex(L, 3*N);
	int lworkl = 3*(ncv*ncv) + 5*ncv;
	double complex * workl = alloc_doublecomplex(L, lworkl);
	double * rwork = alloc_double(L, ncv);
	int info = 0;

	//int count = 0;

	znaupd_(&ido, bmat, &N, which, &nev, &tol, resid, &ncv, V, &ldv, iparam, ipntr, workd, workl, &lworkl, rwork, &info);
	if (ido != -1) {
		arpack_info (L, info);
		luaL_error(L, "expected ido = -1, got ido = %d", ido);
	}
	while(ido == -1 || ido == 1) {
		//printf("\rloop %d",++count); fflush(stdout);
		size_t posX = ipntr[0] - 1;
		array2table(L, 1, N, &workd[posX]);
		//for (int k=0;k<N;k++) {double complex cx = workd[posX + k];printf("%d | %f %f \n",k+1,creal(cx),cimag(cx));}
		// Y = OP * X
		lua_pushvalue(L, 4); // lua function
		lua_pushvalue(L, 1);
		lua_call(L, 1, 0);
		size_t posY = ipntr[1] - 1;
		table2array(L, 1, N, &workd[posY]);
		//for (int k=0;k<N;k++) { double complex cy = workd[posY + k]; printf("%d | %f %f \n",k+1,creal(cy),cimag(cy));}
		znaupd_(&ido, bmat, &N, which, &nev, &tol, resid, &ncv, V, &ldv, iparam, ipntr, workd, workl, &lworkl, rwork, &info);

		lua_gc(L, LUA_GCCOLLECT, 0);
	}
	//printf("\n");
	if (ido != 99)  {
		arpack_info (L, info);
		luaL_error(L, "expected ido = 99, got ido = %d", ido);
	}

	printf("|\tMXITER:\t %10d\t|\n", iparam[2]);
	printf("|\tNCONV:\t %10d\t|\n", iparam[4]);
	printf("|\tNUMOP:\t %10d\t|\n", iparam[8]);
	printf("|\tNUMREO:\t %10d\t|\n", iparam[10]);

	int rvec = true; // compute ritz vectors
	char * howmny = "A";
	int select[ncv];
	double complex * D = alloc_doublecomplex(L, nev+1); // On exit, D contains the Ritz value approximations to the eigenvalues of A*z = lambda*B*z.
	double complex * Z = alloc_doublecomplex(L, N*nev);
	int ldz = N;
	double complex sigma = 0; // If IPARAM(7) = 3 represents the shift. Not referenced if IPARAM(7) = 1 or 2.
	double complex * workev = alloc_doublecomplex(L, 2*ncv);

	zneupd_(&rvec, howmny, select, D, Z, &ldz, &sigma, workev,
	bmat, &N, which, &nev, &tol, resid, &ncv, V, &ldv, iparam, ipntr, workd, workl, &lworkl, rwork, &info);
	arpack_info (L, info);

	FILE *fptr;
	char name [15];
	strcpy(name, "EVALS-0000.mat");
	if (file_exists(name)) {
		for (int i=1; i<=1000; i++) {
			assert( sprintf(name, "EVALS-%04d.mat", i) == 14);
			if (! file_exists(name)) break;
			if (i == 1000) luaL_error(L, "error trying to find a file name for EVALS\n");
		}
	}
	printf("SAVING EIGENVALUES AT %s ... ",name);
	fptr = fopen(name,"w");
	lua_pushlstring(L, name, 14);
	if (fptr == NULL) luaL_error(L, "Error opening file %s", name);
	fprintf(fptr, "# Created by iota.sparse.eigs.arpack\n");
	fprintf(fptr, "# name: EVALS\n");
	fprintf(fptr, "# type: complex matrix\n");
	fprintf(fptr, "# rows: %d\n", nev);
	fprintf(fptr, "# columns: 1\n");
	for (int i = 0; i < nev; ++i) {
		double complex c = D[i];
		fprintf(fptr, " (%.17e,%.17e)\n", creal(c),cimag(c));
	}
	fclose(fptr);
	printf("OK\n");
	if (rvec) {
		strcpy(name, "EVECS-0000.mat");
		if (file_exists(name)) {
			for (int i=1; i<=1000; i++) {
				assert( sprintf(name, "EVECS-%04d.mat", i) == 14);
				if (! file_exists(name)) break;
				if (i == 1000) luaL_error(L, "error trying to find a file name for EVECS\n");
			}
		}
		printf("SAVING EIGENVECTORS AT %s ... ",name);
		fptr = fopen(name,"w");
		lua_pushlstring(L, name, 14);
		if (fptr == NULL) luaL_error(L, "error opening file %s", name);
		fprintf(fptr, "# Created by iota.sparse.eigs.arpack\n");
		fprintf(fptr, "# name: EVECS\n");
		fprintf(fptr, "# type: complex matrix\n");
		fprintf(fptr, "# rows: %d\n", N);
		fprintf(fptr, "# columns: %d\n", nev);
		for (int j = 0; j < N; j++)  {
			for (int i = 0; i < nev; i++) {
				double complex c = V[j + N*i];
				 fprintf(fptr, " (%.17e,%.17e)", creal(c),cimag(c));
			}
			fprintf(fptr, "\n");
		}
		fclose(fptr);
		printf("OK\n");
	}

	return 2;
}

static const struct luaL_Reg lib [] = {
	{"standard", standard},
	{NULL, NULL}
};

int luaopen_iota_sparse_arpack (lua_State *L) {
	luaL_newmetatable(L, EIGSTYPE);
	luaL_newlib(L, lib);
	lua_pushliteral(L,"version");			/** version */
	lua_pushliteral(L,MYVERSION);
	lua_settable(L,-3);
	return 1;
}
