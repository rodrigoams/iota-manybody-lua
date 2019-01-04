# these will probably work if Lua has been installed globally
LUA= /usr/local
LUAINC= $(LUA)/include
LUALIB= $(LUA)/lib
LUABIN= $(LUA)/bin

# probably no need to change anything below here
RM= rm
CC= gcc
CFLAGS= -std=c99 $(INCS) $(WARN) -march=native -Ofast -ftree-vectorize -fopt-info-vec-optimized $G -fPIC
#CFLAGS= -std=c99 $(INCS) $(WARN) -O2 -fopt-info-vec-optimized $G -fPIC
WARN= -pedantic -Wall -Wextra
INCS= -I$(LUAINC)
MAKESO= $(CC) -shared
#MAKESO= $(CC) -bundle -undefined dynamic_lookup

.PHONY: all clean doc

all: ket.so tuple.so

test: ket.so tuple.so space.lua
	$(LUABIN)/lua test_ket.lua
	$(LUABIN)/lua test_hubbard.lua
	$(LUABIN)/lua test_space.lua

ket.so: ket.o
	$(MAKESO) -o ket.so ket.o $(DIR)/complex/number.so

tuple.so: tuple.o
	$(MAKESO) -o tuple.so tuple.o

clean:
	$(RM) *.o *.so

doc:
	@echo "iota.fock.tuple library:"
	@fgrep '/**' tuple.c | cut -f2 -d/ | tr -d '*' | sort
	@echo "iota.fock.ket library:"
	@fgrep '/**' ket.c | cut -f2 -d/ | tr -d '*' | sort

ket.o: ifock.h ket.c
tuple.o: ifock.h tuple.c

#eof
