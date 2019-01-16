export DIR = $(dir $(PWD))

#mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
#current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

export LUA_PATH=$(DIR)?.lua
export LUA_CPATH=$(DIR)?.so

# these will probably work if Lua has been installed globally
export LUA= /usr/local
export LUAINC= $(LUA)/include
export LUALIB= $(LUA)/lib
export LUABIN= $(LUA)/bin

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
SUBDIRS = complex fock sparse

.PHONY: all doc clean lua $(SUBDIRS) $(LUASOURCE)

all: $(LUASOURCE) $(SUBDIRS)

$(LUASOURCE):
	$(MAKE) -C $(LUASOURCE) linux

$(SUBDIRS):
	$(MAKE) -C $@ DIR=$(DIR)

doc: complex fock
	@$(MAKE) -C complex doc
	@$(MAKE) -C fock doc

clean:
	$(MAKE) -C complex clean
	$(MAKE) -C fock clean
	$(MAKE) -C sparse clean

test: $(SUBDIRS) parser
	@$(MAKE) -C complex test
	@$(MAKE) -C fock test
	@$(MAKE) -C parser test
	@$(MAKE) -C sparse test

fock: complex

#eof
