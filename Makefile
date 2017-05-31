OSFLAG :=
MS :=
ifeq ($(OS),Windows_NT)
	OSFLAG = w
	ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
		MS = 64
	endif
	ifeq ($(PROCESSOR_ARCHITECTURE),x86)
		MS = 32
	endif
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSFLAG = l
	endif
	ifeq ($(UNAME_S),Darwin)
		OSFLAG = m
	endif
	MS=$(shell getconf LONG_BIT)  # 32/64
endif
QARCH=$(OSFLAG)$(MS)
Q=${QHOME}/$(QARCH)

ifeq ($(OS),Windows_NT)
KAFKA_ROOT=librdkafka.redist.0.9.5
PTHREADS_ROOT=pthreads.2.9.1.4
KFK_INCLUDE=${KAFKA_ROOT}/build/native/include/
INCLUDES=-I${KFK_INCLUDE}
OPTS=-DKXVER=3 -DWIN32 -Wall -Wno-strict-aliasing -Wno-parentheses -shared -fPIC 
KFK_LD=${KAFKA_ROOT}/runtimes/win7-x64/native/
LDOPTS=-L${KFK_LD} -lws2_32 -lrdkafka
TGT=libkfk.dll
else
KAFKA_ROOT=${HOME}
KFK_INCLUDE=${KAFKA_ROOT}/include
OPTS=-DKXVER=3 -Wall -Wno-strict-aliasing -Wno-parentheses -shared -fPIC 
LDOPTS_STATIC=${KAFKA_ROOT}/lib/librdkafka.a -lz -lpthread -g -O2
LDOPTS=-L${KAFKA_ROOT}/lib/ -lrdkafka -lz -lpthread -g -O2
TGT=libkfk.so
endif

all: $(QARCH)

static: $(addsuffix st,$(QARCH))

install:
	install $(TGT) $(Q)

fmt:
	clang-format -style=file kfk.c -i

print-%  : ; @echo $* = $($*)

m64:
	$(CC) kfk.c -m64 $(OPTS) $(LDOPTS) -I$(KFK_INCLUDE) -o $(TGT) -undefined dynamic_lookup  -mmacosx-version-min=10.12

m64st:
	$(CC) kfk.c -m64 $(OPTS) $(LDOPTS_STATIC) -I$(KFK_INCLUDE) -o $(TGT) -undefined dynamic_lookup -lssl  -mmacosx-version-min=10.12

w32:
	$(CC) kfk.c -m32 $(OPTS) $(LDOPTS) -I$(KFK_INCLUDE)

w64:
	$(CC) kfk.c -m64 $(OPTS) $(LDOPTS) $(INCLUDES) q.lib -lws2_32

l32:
	$(CC) kfk.c -m32 $(OPTS) $(LDOPTS) -I$(KFK_INCLUDE) -o $(TGT)
 
l64:
	$(CC) kfk.c -m64 $(OPTS) $(LDOPTS) -I$(KFK_INCLUDE) -o $(TGT)

l64st:
	$(CC) kfk.c -m64 $(OPTS) $(LDOPTS_STATIC) -I$(KFK_INCLUDE) -o $(TGT)


