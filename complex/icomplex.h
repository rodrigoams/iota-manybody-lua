#ifndef _iCOMPLEX_H
#define _iCOMPLEX_H

/*
* iota.complex library
* C99 complex numbers for Lua 5.4
* Rodrigo A. Moreira <rodrigoams@gmail.com>
* 3 Jan 2018 10:08:23
* This code is hereby placed in the public domain.
*/

#include <complex.h>
#include <string.h>
#include <stdbool.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

typedef LUA_NUMBER complex iComplex;

#define MYNAME "complex"
#define COMPLEXTYPE MYNAME " number"
#define COMPLEXARRAYTYPE	MYNAME " array"

iComplex icheckcomplex (lua_State *L, int i) {
	iComplex ret;
	switch (lua_type(L,i)) {
		case LUA_TNUMBER:
		case LUA_TSTRING: { ret = (iComplex) luaL_checknumber(L,i); break ; }
		default: ret = *((iComplex*)luaL_checkudata(L,i,COMPLEXTYPE));
	}
	return ret;
}

int ipushcomplex(lua_State *L, iComplex z) {
	iComplex *p = lua_newuserdata(L,sizeof(iComplex));
	*p = z;
	luaL_setmetatable(L,COMPLEXTYPE);
	return 1;
}

typedef struct iComplexNumberArray {
	lua_Integer size;
	iComplex values[1];  /* variable part */
} iComplexNumberArray;

int luaopen_iota_complex_number(lua_State *L);
int luaopen_iota_complex_array (lua_State *L);

#endif
