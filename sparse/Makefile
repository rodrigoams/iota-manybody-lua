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

all: arpack.so

arpack.so: arpack.o
	$(MAKESO) -o arpack.so arpack.o -larpack -lm

clean:
	$(RM) *.o *.so
	$(RM) EVAL*.mat EVEC*.mat

test: arpack.so
	$(LUABIN)/lua test_arpack.lua

doc:
	@echo "iota.sparse.arpack library:"
	@fgrep '/**' arpack.c | cut -f2 -d/ | tr -d '*' | sort


#eof
