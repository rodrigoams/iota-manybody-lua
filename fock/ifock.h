#ifndef _iFOCK_H
#define _iFOCK_H

/*
* iota.fock library
* fock, ket and tuple library for Lua 5.4
* Rodrigo A. Moreira <rodrigoams@gmail.com>
* 3 Jan 2018 10:08:23
* This code is hereby placed in the public domain.
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "../complex/icomplex.h"

#define KET_TNONE		 0
#define KET_TFERMION	-1
#define KET_TBOSON		 1
#define KET_TBOSON2	 2

typedef unsigned char uk;

typedef struct ukb {
	uk num;
	char sym; // symmetry storage, really an overkill
} struct_ukb;

#define UKn(a,k) ((a->b[k]).num)
#define UKs(a,k) ((a->b[k]).sym)

typedef struct struct_ket {
	bool is_copy;
	iComplex coef;
	size_t size; // número de slots disponíveis
	size_t len; // número de slots utilizados
	struct_ukb b[1];
} struct_ket;

typedef struct struct_tuple {
	lua_Unsigned size;
} struct_tuple;

struct_ket * ket_construct(lua_State *L, lua_Integer n, iComplex coef) {
	if (n < 0) luaL_error(L,"the number of elements must be >= 0.");
	size_t nbytes = sizeof(struct_ket) + ((n+5)-1)*sizeof(struct_ukb);
	struct_ket * array = (struct_ket *)lua_newuserdata(L, nbytes);
	
     // Inicializando o array
	array->len = n;
	array->coef = coef;
	array->size = n + 5; // slots (5) extras para diminuir a alocação de memória
	array->is_copy = false;
	for(size_t k=0; k<array->size; k++) {
		UKn(array,k) = 0u;
		UKs(array,k) = KET_TNONE;
	}
	
	luaL_setmetatable(L, "fock.ket");

	return array;
}

#endif
