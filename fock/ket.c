#include "ifock.h"

#define MYVERSION "fock.ket from ιlibrary for " LUA_VERSION " / Jan 2019"

static uk ket_checkuk(lua_State *L, int arg) {
	lua_Integer i = luaL_checkinteger(L, arg);
	if ((uk)(i) != i) luaL_error(L, "integer %d out of range of unsigned %d bytes.", i, sizeof(uk));
    if ((uk)(i) == 0) luaL_error(L, "the basis must be numbered by unsigned integers >= 1");
	return (uk)(i);
}

/** check(ket)			: return boolean		:  true if metatable(fock.ket) == 'fock.ket' */
static int ket_check(lua_State *L) {
	lua_pushboolean(L, luaL_testudata(L,1,"fock.ket") != NULL  );
	return 1;
}

/** ket:copy()			: return  ket			:  ket->copy = true */
static int ket_copy(lua_State *L) {
	//printf("CONSTRUCTING NEW KET\n");
	struct_ket * array = luaL_checkudata(L, 1, "fock.ket");
	if ( array->len > array->size ) luaL_error(L, "ket 'len' cannot be grater than ket 'size'.");

	struct_ket * arrayn = ket_construct(L, array->len, array->coef);

	for(size_t i=0; i < array->len; i++) {
		UKn(arrayn,i) = UKn(array,i);
		UKs(arrayn,i) = UKs(array,i);
	}

	arrayn->is_copy = false;

	return 1;
}

/** ket2str(ket)			: return long string		:  unique id of |ket> */
static int ket_ket2str(lua_State *L) {
	struct_ket * array = luaL_checkudata(L, 1, "fock.ket");
	lua_pushlstring(L, (const char*)array->b, (array->len)*sizeof(struct ukb));
	return 1;
}

/** str2ket(string)		: return ket			:  from ket2str() */
static int ket_str2ket(lua_State *L) {
	size_t l;
	struct_ukb * b  = (struct_ukb *)luaL_checklstring(L,1,&l);
	l = l/sizeof(struct_ukb);
	struct_ket * ket = ket_construct(L,l,1.0);
	for (size_t k=0;k<l;k++) {
		UKn(ket,k) = b[k].num;
		UKs(ket,k) = b[k].sym;
	}
	return 1;
}

/** __len(ket)			: return  unsigned integer	:  ket->len */
static int ket__len(lua_State *L) {
	struct_ket * array = luaL_checkudata(L, 1, "fock.ket");
	lua_pushinteger(L,(lua_Integer)array->len);
	return 1; // array->len
}

/** __mul(c,ket)			: return ket			:  ket->coef = c.ket->coef */
static int ket__mul(lua_State *L) {
	struct_ket * array = luaL_checkudata(L, 2, "fock.ket");
	array->coef = array->coef * icheckcomplex(L, 1);
	return 1; // array
}

/** ket:getcoef()			: return  number		:  ket->coef */
static int ket_getcoef(lua_State *L) {
	struct_ket * array = luaL_checkudata(L, 1, "fock.ket");
	ipushcomplex(L, array->coef);
	return 1;
}

/** ket:setcoef(c)			: return  ket			:  ket->coef = c */
static int ket_setcoef(lua_State *L) {
	struct_ket * array = luaL_checkudata(L, 1, "fock.ket");
	array->coef = icheckcomplex(L, 2);
	lua_pop(L,1); // coef
	return 1;
}

/** ket:iscopy()			: return  boolean		:  ket->copy */
static int ket_iscopy(lua_State *L) {
	struct_ket * array = luaL_checkudata(L, 1, "fock.ket");
	lua_pushboolean(L, array->is_copy);
	return 1;
}

/** ket:getbasis()			: return  multiple integers	:  ket->uk->num[] */
static int ket_getbasis (lua_State *L) {
	struct_ket * array = luaL_checkudata(L, 1, "fock.ket");
	size_t n = array->len;
	luaL_checkstack(L, n, "not enough stack space.");
	for (size_t k=0; k<n; k++) lua_pushinteger(L, (unsigned)(lua_Integer)UKn(array,k));
	return n;
}

/** ket:getsyms()			: return  multiple integers	:  ket->uk->sym[] */
static int ket_getsyms (lua_State *L) {
	struct_ket * array = luaL_checkudata(L, 1, "fock.ket");
	size_t n = array->len;
	luaL_checkstack(L, n, "not enough stack space.");
	for (size_t k=0; k<n; k++) lua_pushinteger(L, (lua_Integer)UKs(array,k));
	return n;
}

static struct_ket * ket_replace (lua_State *L) {
	//printf("KET_REPLACE\n");
	// ket at stack position 1
	ket_copy(L); // it also update ket 'size'
	struct_ket * arrayn = (struct_ket *)lua_touserdata(L, -1);
	arrayn->is_copy = true;
	lua_replace(L, 1);
	return arrayn;
}

/** __tostring()			: return  string		:  coef | b1 b2 ... bn > */
static int ket__tostring (lua_State *L) {
	struct_ket * ket = luaL_checkudata(L, 1, "fock.ket");
	luaL_Buffer b;
	luaL_buffinit(L, &b);
	
	ipushcomplex(L,ket->coef);
	luaL_tolstring(L,-1,NULL);
	luaL_addvalue(&b);
	
	luaL_addstring(&b," | ");
	
	for(size_t i=0; i<ket->len; i++) { 
		lua_pushinteger(L,UKn(ket,i));
		luaL_addvalue(&b);
		luaL_addstring(&b," ");
	}
	if (ket->len == 0) luaL_addstring(&b,"∅ ");//\u2205 ");
	
	luaL_addstring(&b,"⟩");//"\u27E9 ");
	
	luaL_pushresult(&b);
	return 1;
}

/** ket:C(n,sym)			: return  ket			:  C^dagger_n | ket > */
static int ket_create (lua_State *L) {
	/* BEGGING OF DEFAULT OP PREAMBLE */
	//if (lua_gettop(L) != 3) luaL_error(L, "expected 3 arguments.");

	struct_ket * array = luaL_checkudata(L, 1, "fock.ket");
	uk n = ket_checkuk(L, 2);
	
	lua_Integer bnsym = luaL_checkinteger(L, 3);

	lua_pop(L, lua_gettop(L)-1); // n and bsym
	
	lua_Number coef = array->coef;
	
	if (fabs(coef) == 0.0) { // return equivalent of null ket: 0.0|∅>
		array->len = 0;
		return 1;
	}
	
	if (! array->is_copy) {
		array = ket_replace(L);
		//printf("array replace copy\n");
	}
	/* END OF DEFAULT OP PREAMBLE */

	int nigual = 1;
	int nchanges = 0;
	int pos = -1;
	
	for (size_t j=0; j<array->len; j++) {
		if ((pos == -1) && (UKn(array,j) >= n)) pos = j;
		if ((pos > -1) && (UKs(array,j) == KET_TFERMION )) nchanges++;
		if ( UKn(array,j) == n ) nigual++;
	}

	if (pos == -1) pos = array->len;
	size_t len = array->len+1;

    if (len == array->size) {
		array = ket_replace(L);
		//printf("replace due to size\n");
	}

	if ( bnsym == KET_TFERMION ) {
		if ( nigual == 1 ) coef = coef*(nchanges & 1 ? -1:1 );//pow(-1.0,nchanges);
		else { coef = 0.0; len = 0;}
	}
	else if ( bnsym == KET_TBOSON ) coef = coef*nigual;
	else if ( bnsym == KET_TBOSON2 ) coef = coef;
	else luaL_error(L, "wrong symmetry");

	array->len = len;
	array->coef = coef;

	//printf("New len: %ld\nNew coef: %f\n", array->len, array->coef);

	if ( len > 0 ) {
		struct ukb buf = array->b[pos];
		UKn(array,pos) = n;
		UKs(array,pos) = bnsym;
		for (size_t k=pos+1; k<array->len; k++) {
			struct ukb buf2 = array->b[k];
			array->b[k] = buf;
			buf = buf2;
		}
	}

	return 1;
}

/** ket:Cf(n)			: return  ket			:  fermionic C^dagger_n | ket > */
static int ket_createFermion(lua_State *L) {
	lua_pushinteger(L, KET_TFERMION);
	ket_create(L);
	return 1;
}

/** ket:Cb(n)			: return  ket			:  bosonic C^dagger_n | ket > */
static int ket_createBoson(lua_State *L) {
	lua_pushinteger(L, KET_TBOSON);
	ket_create(L);
	return 1;
}

/** ket:A(n,sym)			: return  ket			:  C_n | ket > */
static int ket_annihilate (lua_State *L) {
	/* BEGGING OF DEFAULT OP PREAMBLE */
	//if (lua_gettop(L) != 3) luaL_error(L, "expected 3 arguments.");

	struct_ket * array = lua_touserdata(L, 1); //luaL_checkudata(L, 1, "fock.ket");
	uk n = ket_checkuk(L, 2);
	lua_Integer bnsym = lua_tointeger(L, 3);
	if (bnsym == KET_TNONE) luaL_error(L,"Incorrect symmetry specified.");

	lua_pop(L, lua_gettop(L)-1); // n and/or bsym
	
	lua_Number coef = array->coef;
	
	if (fabs(coef) == 0.0) { // return equivalent of null ket: 0.0|∅>
		array->len = 0;
		return 1;
	}
	
	if (! array->is_copy || array->len == array->size) array = ket_replace(L);
	/* END OF DEFAULT OP PREAMBLE */

	int nigual = 0;
	int nfermions = 0;
	int first_pos = 0;

	for (size_t j=0; j<array->len; j++) {
		if ( UKs(array,j) == -1 ) nfermions++;
		if ( UKn(array,j) == n ) {
			nigual++;
			if (first_pos == 0) first_pos = j+1;
		}
	}

   //printf("nigual %d, nfermions %d, first_pos %d\n",nigual,nfermions,first_pos);

	int len = first_pos > 0 ? (int)(array->len - 1) : 0;

	if ( first_pos > 0 ){
		if (bnsym == KET_TFERMION ) coef = coef*((nfermions + first_pos) & 1 ? -1:1 );//coef*pow(-1.0, first_pos + nfermions);
		else if (bnsym == KET_TBOSON) coef = coef;
		else if (bnsym == KET_TBOSON2) coef = coef*nigual;
		else luaL_error(L, "wrong symmetry");

		for (size_t k=first_pos; k<array->len; k++) array->b[k-1] = array->b[k];

	} else {
		coef = 0.0;
		len = 0;
	}

	array->len = len;
	array->coef = coef;

	return 1;
}

/** ket:Af(n)			: return  ket			:  fermionic C_n | ket > */
static int ket_annihilateFermion(lua_State *L) {
	lua_pushinteger(L, KET_TFERMION);
	ket_annihilate(L);
	return 1;
}

/** ket:Ab(n)			: return  ket			:  bosonic C_n | ket > */
static int ket_annihilateBoson(lua_State *L) {
	lua_pushinteger(L, KET_TBOSON);
	ket_annihilate(L);
	return 1;
}

/** ket:N(n,sym)			: return  ket			:  N_n | ket > */
static int ket_number (lua_State *L) {
	/* BEGGING OF DEFAULT OP PREAMBLE */
	//if (lua_gettop(L) != 3) luaL_error(L, "expected 3 arguments.");

	struct_ket * array = lua_touserdata(L, 1); //luaL_checkudata(L, 1, "fock.ket");
	uk n = ket_checkuk(L, 2);
	lua_Integer bnsym = lua_tointeger(L, 3);
	if (bnsym == KET_TNONE) luaL_error(L,"Incorrect symmetry specified.");

	lua_pop(L, lua_gettop(L)-1); // n and/or bsym
	
	lua_Number coef = array->coef;
	
	if (fabs(coef) == 0.0) { // return equivalent of null ket: 0.0|∅>
		array->len = 0;
		return 1;
	}
	
	if (! array->is_copy || array->len == array->size) array = ket_replace(L);
	/* END OF DEFAULT OP PREAMBLE */
	
	int nigual = 0;
	for (size_t j=0; j<array->len; j++)
		if ( UKn(array,j) == n ) nigual++;

	array->coef = nigual*coef;
	//if (array->coef == 0) array->len = 0;
	
	return 1;
}

/** ket:Nf(n,sym)			: return  ket			:  fermionic N_n | ket > */
static int ket_numberFermion(lua_State *L) {
	lua_pushinteger(L, KET_TFERMION);
	ket_number(L);
	return 1;
}

/** ket:Nb(n)			: return  ket			:  bosonic N_n | ket > */
static int ket_numberBoson(lua_State *L) {
	lua_pushinteger(L, KET_TBOSON);
	ket_number(L);
	return 1;
}

static const luaL_Reg ket_m [] = {
	{"C", ket_create},
	{"Cf", ket_createFermion},
	{"Cb", ket_createBoson},
	
	{"A", ket_annihilate},
	{"Af", ket_annihilateFermion},
	{"Ab", ket_annihilateBoson},
	
	{"N", ket_number},
	{"Nf", ket_numberFermion},
	{"Nb", ket_numberBoson},
	
	//{"get", ket_get},
	
	{"getcoef",ket_getcoef},
	{"setcoef",ket_setcoef},
	
	{"getbasis",ket_getbasis},
	{"getsyms",ket_getsyms},
	
	{"copy", ket_copy},
	{"iscopy",ket_iscopy},
	
	// __metamethods
	{"__len",ket__len},
	{"__mul",ket__mul},
	{"__tostring",ket__tostring},
	{NULL, NULL}
};

static const luaL_Reg fock_ket[] = {
	{"check",ket_check},
	{"ket2str",ket_ket2str},
	{"str2ket",ket_str2ket},
	{NULL, NULL}
};

/*
** Open Ket library
*/
int luaopen_iota_fock_ket (lua_State *L) {
	luaL_requiref(L,"iota.complex.number",luaopen_iota_complex_number,true);
	
	// CREATE METATABLE
	
	luaL_newmetatable(L, "fock.ket");
	
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);  /* pushes the metatable */
	lua_settable(L, -3);  /* metatable.__index = metatable */
	luaL_setfuncs(L, ket_m, 0);
	lua_pop(L, 1);
	
	// CREATE_LIB
	
	luaL_newlib(L, fock_ket);
	
	lua_pushinteger(L, KET_TFERMION);
	lua_setfield(L, -2, "fermion"); /** fermion  			: sym id*/
	
	lua_pushinteger(L, KET_TBOSON);
	lua_setfield(L, -2, "boson"); /** boson 				: sym id */
	
	lua_pushinteger(L, KET_TBOSON2);
	lua_setfield(L,-2,"boson2"); /** boson2 			: sym id */
	
	ket_construct(L, 0, 1.0);
	lua_setfield(L,-2,"vac"); /** vac 				: return ket with zero particles */
	
	ket_construct(L, 0, 0.0);
	lua_setfield(L,-2,"null"); /** null 				: return null ket*/
	
	lua_pushliteral(L,"version");			/** version */
	lua_pushliteral(L,MYVERSION);
	lua_settable(L,-3);
	
	return 1;
}
