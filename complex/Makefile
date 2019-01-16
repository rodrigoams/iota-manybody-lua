# probably no need to change anything below here
RM= rm
CC= gcc
CFLAGS= -std=c99 $(INCS) $(WARN) -march=native -Ofast -fopenmp $G -fPIC
WARN= -pedantic -Wall -Wextra
INCS= -I$(LUAINC)
MAKESO= $(CC) -shared
#MAKESO= $(CC) -bundle -undefined dynamic_lookup

.PHONY: all clean doc

all: number.so array.so

test: number.so array.so
	$(LUABIN)/lua test.lua
	$(LUABIN)/lua test_array.lua

number.so: number.o
	$(MAKESO) -o number.so number.o

array.so: array.o number.so
	$(MAKESO) -fopenmp -o array.so array.o number.so

clean:
	$(RM) *.so *.o

doc:
	@echo "iota.complex.number library:"
	@fgrep '/**' number.c | cut -f2 -d/ | tr -d '*' | sort | column
	@echo "iota.complex.array library:"
	@fgrep '/**' array.c | cut -f2 -d/ | tr -d '*' | sort

number.o: icomplex.h number.c
array.o: icomplex.h array.c

# eof
