DIR= $(PWD)

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

LUASOURCE = lua-5.4.0-work2
LUACODES = fock/space.lua fock/driver.lua sparse/matrix.lua
SUBDIRS = complex fock

.PHONY: all doc clean lua $(SUBDIRS) $(LUACODES)

all: $(LUASOURCE) $(SUBDIRS) $(LUACODES)

$(LUASOURCE): $(LUASOURCE).tar.gz
	[ -d $(LUASOURCE) ] || tar zxvf $(LUASOURCE).tar.gz
	$(MAKE) -C $(LUASOURCE) linux CFLAGS=-fPIC

$(SUBDIRS):
	$(MAKE) -C $@ DIR=$(DIR)

doc: complex fock
	@$(MAKE) -C complex doc
	@$(MAKE) -C fock doc

clean:
	$(MAKE) -C complex clean
	$(MAKE) -C fock clean
	[ -d $(LUASOURCE) ] && $(RM) -rf $(LUASOURCE)

test: complex fock
	@$(MAKE) -C complex test
	@$(MAKE) -C fock test

fock: complex

#eof
