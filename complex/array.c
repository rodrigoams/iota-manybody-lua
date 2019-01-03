#include "icomplex.h"

#define MYVERSION COMPLEXARRAYTYPE " from ιlibrary  for " LUA_VERSION " / Jan 2019"

/** new(n)					: return  complex array		: array->size = n */
static int newarray (lua_State *L) { 
	lua_Integer n = luaL_checkinteger(L, 1);
	size_t nbytes = sizeof(iComplexNumberArray) + (n - 1)*sizeof(iComplex);
	iComplexNumberArray *a = (iComplexNumberArray *)lua_newuserdata(L, nbytes);
	memset(a->values, 0, sizeof(iComplex)*n);
	a->size = n;
	luaL_setmetatable(L,COMPLEXARRAYTYPE);
	return 1;  /* new userdatum is already on the stack */
}

/** set(array,k,v)				: return  nil			: array->values[k] = v */
static int setarray (lua_State *L) { 
	iComplexNumberArray *a = (iComplexNumberArray *)luaL_checkudata(L, 1, COMPLEXARRAYTYPE);
	lua_Integer index = luaL_checkinteger(L, 2);
	iComplex value = icheckcomplex(L, 3);
	luaL_argcheck(L, 1 <= index && index <= a->size, 2,"index out of range");
	a->values[index-1] = value;
	return 0;
}

/** get(array,n)				: return  complex array		: array->values[k] */
static int getarray (lua_State *L) { 
	iComplexNumberArray *a = (iComplexNumberArray *)luaL_checkudata(L, 1, COMPLEXARRAYTYPE);
	lua_Integer index = luaL_checkinteger(L, 2);
	luaL_argcheck(L, 1 <= index && index <= a->size, 2,"index out of range");
	ipushcomplex(L, a->values[index-1]);
  return 1;
}

/** size(array)				: return  integer		: array->size */
static int getsize (lua_State *L) {
	iComplexNumberArray *a = (iComplexNumberArray *)luaL_checkudata(L, 1, COMPLEXARRAYTYPE);
	lua_pushinteger(L, a->size);
	return 1;
}

static int checkboolean(lua_State *L, int n) {
	luaL_checktype(L,n,LUA_TBOOLEAN);
	return lua_toboolean(L,n);
}

static int inner (lua_State *L) {/** inner(array1,array2,conj1,conj2)	: return  complex number	: sum += conj1(array1).conj2(array2) */
	iComplexNumberArray *a = (iComplexNumberArray *)luaL_checkudata(L, 1, COMPLEXARRAYTYPE);
	iComplexNumberArray *b = (iComplexNumberArray *)luaL_checkudata(L, 2, COMPLEXARRAYTYPE);
	if (a->size != b->size ) luaL_error(L, "`arrays' with same dimensions expected");
	int conj1 = checkboolean(L,3);
	int conj2 = checkboolean(L,4);
	iComplex sum = 0.0;
	#pragma omp parallel for default(shared) reduction(+:sum)
	for (lua_Integer k=0; k < a->size; k++) {
		iComplex val1 = conj1 ? conj(a->values[k]) : a->values[k];
		iComplex val2 = conj2 ? conj(b->values[k]) : b->values[k];
		sum += val1*val2;
	}
	ipushcomplex(L, sum);
	return 1;
}

 /** xayb(array1,x,array2,y,conj1,conj2)	: return  complex array		: array2 = conj1(array1)x + conj2(array2)y */
static int xayb (lua_State *L) {
	iComplexNumberArray *a = (iComplexNumberArray *)luaL_checkudata(L, 1, COMPLEXARRAYTYPE);
	iComplex x = icheckcomplex(L,2);
	iComplexNumberArray *b = (iComplexNumberArray *)luaL_checkudata(L, 3, COMPLEXARRAYTYPE);
	iComplex y = icheckcomplex(L,4);
	if (a->size != b->size ) luaL_error(L, "`arrays' with same dimensions expected");
	int conj1 = checkboolean(L,5);
	int conj2 = checkboolean(L,6);
	#pragma omp parallel for default(shared)
	for (lua_Integer k=0; k < a->size; k++) {
		iComplex val1 = conj1 ? conj(a->values[k]) : a->values[k];
		iComplex val2 = conj2 ? conj(b->values[k]) : b->values[k];
		b->values[k] = val1*x + val2*y;
	}
	return 0;
}

/** xcopy(array1,x,array2,conj1) 		: return  complex array		: array2 = conj1(array1)x */
static int xcopy (lua_State *L) { 
	iComplexNumberArray *a = (iComplexNumberArray *)luaL_checkudata(L, 1, COMPLEXARRAYTYPE);
	iComplex x = icheckcomplex(L,2);
	iComplexNumberArray *b = (iComplexNumberArray *)luaL_checkudata(L, 3, COMPLEXARRAYTYPE);
	if (a->size != b->size ) luaL_error(L, "`arrays' with same dimensions expected");
	int conj1 = checkboolean(L,4);
	#pragma omp parallel for default(shared)
	for (lua_Integer k=0; k < a->size; k++) {
		iComplex val1 = conj1 ? conj(a->values[k]) : a->values[k];
		b->values[k] = val1*x;
	}
	return 0;
}

static const struct luaL_Reg arraylib [] = {
	{"new", newarray},
	{"set", setarray},
	{"get", getarray},
	{"size", getsize},
	{"inner",inner},
	{"xayb",xayb},
	{"xcopy",xcopy},
	{NULL, NULL}
};

int luaopen_iota_complex_array (lua_State *L) {
	luaL_requiref(L,"iota.complex.number",luaopen_iota_complex_number,true);
	luaL_newmetatable(L, COMPLEXARRAYTYPE);
	luaL_newlib(L, arraylib);
	lua_pushliteral(L,"version");			/** version */
	lua_pushliteral(L,MYVERSION);
	lua_settable(L,-3);
	return 1;
}
