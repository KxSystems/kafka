OSFLAG :=
MS :=

KFK_ROOT=${HOME}
KFK_INCLUDE    = ${KFK_ROOT}/include
W_OPTS         = -Wall -Wno-strict-aliasing -Wno-parentheses -Wextra -Werror -Wsign-compare
OPTS           = -DKXVER=3 -shared -fPIC $(W_OPTS)
LD_COMMON      = -lz -lpthread -lssl -g -O2
LDOPTS_DYNAMIC = -L${KFK_ROOT}/lib/ -lrdkafka
LDOPTS_STATIC  = ${KFK_ROOT}/lib/librdkafka.a
MS             = $(shell getconf LONG_BIT)
TGT            = libkfk.so

ifeq ($(shell uname),Linux)
 LNK     = -lrt
 OSFLAG  = l
 OSXOPTS:=
else ifeq ($(shell uname),Darwin)
 OSFLAG  = m
 LNK:=
 OSXOPTS = -undefined dynamic_lookup  -mmacosx-version-min=10.12
endif

QARCH = $(OSFLAG)$(MS)
Q     = $(QHOME)/$(QARCH) 

all: k.h
	$(CC) kfk.c -m$(MS) $(OPTS) $(LDOPTS_DYNAMIC) $(LD_COMMON) -I$(KFK_INCLUDE) $(LNK) -o $(TGT) $(OSXOPTS)
static: k.h
	$(CC) kfk.c -m$(MS) $(OPTS) $(LDOPTS_STATIC)  $(LD_COMMON) -I$(KFK_INCLUDE) $(LNK) -o $(TGT) $(OSXOPTS)
k.h:
	curl -s -O -L https://github.com/KxSystems/kdb/raw/master/c/c/k.h 
install:
	install $(TGT) $(Q)
clean:
	rm -f libkfk.so
