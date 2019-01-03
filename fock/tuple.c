#include "ifock.h"

#define MYVERSION "fock.tuple from ιlibrary for " LUA_VERSION " / Jan 2019"

/** __index(tuple,k)		: return  unsigned integer	:  tuple[k] */
static int tuple__index(lua_State *L) {
	luaL_checkudata(L,1,"fock.tuple");
	int type = lua_type(L,2);
	if (LUA_TTABLE != lua_getiuservalue(L, 1, 1)) luaL_error(L, "Invalid uservalue 1 of tuple!");
	if (type == LUA_TUSERDATA) {
		struct_ket * uket = (struct_ket *)luaL_checkudata(L, 2, "fock.ket");
		lua_pushlstring(L, (const char*)uket->b, (uket->len)*sizeof(struct ukb));
		lua_rawget(L,3);
	}
	else if (type == LUA_TNUMBER) lua_rawgeti(L,3,luaL_checkinteger(L,2));
	else luaL_error(L,"Invalid key to tuple.\n");
	return 1;
}

/** __newindex(tuple,k,v)		: return  nil			:  tuple[k]=v */
static int tuple__newindex(lua_State *L) {
	// P1
	struct_tuple * utuple = luaL_checkudata(L, 1, "fock.tuple");
	// P2
	struct_ket * uket = (struct_ket *)luaL_checkudata(L, 2, "fock.ket");
	// P3
	lua_Integer value = luaL_checkinteger(L, 3);
	if (value != (unsigned)value || value == 0) luaL_error(L,"Invalid tuple value. It must be an integer > 0");
	// P4
	if (LUA_TTABLE != lua_getiuservalue(L, 1, 1)) luaL_error(L, "Invalid uservalue of tuple!");
	// P5
	lua_pushlstring(L, (const char*)uket->b, (uket->len)*sizeof(struct ukb));
	// check if there is such key
	lua_pushvalue(L, 5);
	if (LUA_TNIL != lua_rawget(L, 4)) luaL_error(L,"Same ket with different tuple value! aborting.");
	else lua_pop(L,1); // remove nil
	// if not, add a new one
	lua_pushvalue(L,3);
	lua_rawset(L,4);
	utuple->size++;
	// CHECK AND STORE SYMMETRIES
	for (size_t k=0;k<uket->len;k++) {
		struct_ukb b = uket->b[k];
		int type = lua_rawgeti(L, -1, b.num);
		lua_pushinteger(L, b.sym);
		if (LUA_TNIL == type) { 
			lua_rawseti(L,-3, b.num);
			lua_pop(L,1);
		}
		else {
			if (!lua_compare(L, -1, -2, LUA_OPEQ)) printf("WARNING! TWO IDENTICAL INDEXESS WITH DIFFERENT SYMMETRIES, BE CAREFULL.");
			lua_pop(L,2);
		}
	}
	return 0;
}

/** new(n)				: return  empty fock.tuple	:  tuple->size = 0 */
static int tuple_new(lua_State *L) {
	size_t nbytes = sizeof(struct_tuple);
	struct_tuple * udata = (struct_tuple * )lua_newuserdatauv(L, nbytes, 1);
	udata->size = 0u;
	luaL_setmetatable(L, "fock.tuple");
	lua_createtable(L, 10, 100);
	lua_setiuservalue(L, -2, 1);
	return 1;
}

/** __len(tuple)			: return  unsigned integer	:  tuple->size */
static int tuple_getsize(lua_State *L) {
	lua_pushinteger(L, ((struct_tuple *)luaL_checkudata(L, 1, "fock.tuple"))->size);
	return 1;
}

/*
static void checkstack (lua_State *L) {
	printf("BEGIN STACK:\n");
	for (int k=1; k<=lua_gettop(L); k++) printf("%d\t%s\n", k, lua_typename(L, lua_type(L,k)));
	printf("END STACK\n\n");
}
*/

static int tuple_str2ket(lua_State *L, int n) {
	size_t l;
	struct_ukb * b  = (struct_ukb *)luaL_checklstring(L,n,&l);
	l = l/sizeof(struct_ukb);
	struct_ket * ket = ket_construct(L,l,1.0);
	for (size_t k=0;k<l;k++) {
		UKn(ket,k) = b[k].num;
		UKs(ket,k) = b[k].sym;
	}
	lua_replace(L, n);
	return 1;
}

static int tuple_next(lua_State *L) {
	//checkstack(L);
	lua_settop(L,0); // remove spurious elements on the stack
	lua_pushvalue(L, lua_upvalueindex(1)); // table
	lua_pushvalue(L, lua_upvalueindex(2)); // key
	//checkstack(L);
	if (lua_next(L,1) != 0) {
		lua_pushvalue(L,2); // copy key
		lua_replace(L,lua_upvalueindex(2)); // and replace it
		// SUBSTITUTE STRING AT 2 BY NORMALIZED KET
		if (lua_type(L,2) == LUA_TSTRING) tuple_str2ket(L, 2);
	}
	//checkstack(L);
	lua_settop(L,3);
	return 2;
}

/** __pairs(tuple)			: return  tuple iterator	:  next(),nil,nil */
static int tuple_iter(lua_State *L) {
	if (lua_gettop(L) != 1) luaL_error(L, "Wrong number (%d) of arguments to 'next'. Expected only 1, namely, the tuple.",lua_gettop(L));
	luaL_checkudata(L, 1, "fock.tuple");
	if (LUA_TTABLE != lua_getiuservalue(L, 1, 1)) luaL_error(L, "Invalid uservalue 1 of tuple!");
	lua_pushnil(L);
	//checkstack(L);
	lua_pushcclosure(L, &tuple_next, 2);
	lua_pushnil(L);
	lua_pushnil(L);
	//checkstack(L);
	return 3;
}

static const luaL_Reg ket_m [] = {
	{"__index", tuple__index},
	{"__newindex", tuple__newindex},
	{"__len", tuple_getsize},
	{"__pairs",tuple_iter},
	{NULL, NULL}
};

static const luaL_Reg fock_tuple[] = {
	{"new", tuple_new},
	{NULL, NULL}
};

int luaopen_iota_fock_tuple (lua_State *L) {
	// CREATE METATABLE
	luaL_newmetatable(L, "fock.tuple");
	luaL_setfuncs(L, ket_m, 0);
	lua_pop(L, 1);
	// CREATE LIB
	luaL_newlib(L, fock_tuple);
	
	lua_pushliteral(L,"version");			/** version */
	lua_pushliteral(L,MYVERSION);
	lua_settable(L,-3);
	return 1;
}
