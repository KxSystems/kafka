OSFLAG :=
MS :=

KAFKA_ROOT     =${HOME}
KFK_INCLUDE    =${KAFKA_ROOT}/include
OPTS           =-DKXVER=3 -Wall -Wno-strict-aliasing -Wno-parentheses -shared -fPIC -Wextra -Werror -Wsign-compare -Wwrite-strings
LD_COMMON       =-lz -lpthread -lssl -g -O2
LDOPTS_DYNAMIC =-L${KAFKA_ROOT}/lib/ -lrdkafka
LDOPTS_STATIC  =${KAFKA_ROOT}/lib/librdkafka.a
MS             = $(shell getconf LONG_BIT)
TGT            = libkfk.so

ifeq ($(shell uname),Linux)
 LNK     =-lrt
 OSFLAG  = l
 OSXOPTS:=
else ifeq ($(shell uname),Darwin)
 OSFLAG  = m
 LNK:=
 OSXOPTS =-undefined dynamic_lookup  -mmacosx-version-min=10.12
endif

QLIBDIR  = $(OSFLAG)$(MS)

all:
	$(CC) kfk.c -m$(MS) $(OPTS) $(LDOPTS_DYNAMIC) $(LD_COMMON) -I$(KFK_INCLUDE) $(LNK) -o $(TGT) $(OSXOPTS)
static:
	$(CC) kfk.c -m$(MS) $(OPTS) $(LDOPTS_STATIC)  $(LD_COMMON) -I$(KFK_INCLUDE) $(LNK) -o $(TGT) $(OSXOPTS) 
install:
	install $(TGT) $(QHOME)/$(QLIBDIR)
clean:
	-rm libkfk.so 
