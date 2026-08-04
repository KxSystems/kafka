M:=$(shell $(CC) -dumpmachine)
P:=$(if $(findstring linux,$M),l)$(if $(findstring -apple-,$M),m)$(if $(filter %-mingw32 %-msvc,$M),w)
A:=$(if $(filter x86_64-%,$M),i64)$(if $(filter aarch64-% arm64-%,$M),a64)
T:=$(if $P,$(if $A,$P$A))
$(if $T,,$(error couldn't determine the target platform: $(CC) -dumpmachine reports $M))
H:=$(shell uname -o)

ifndef PREFIX
PREFIX=out/kx
endif

ifndef QMOD
QMOD=1
endif

E=so
ifeq ($P,w)
E=dll
endif

CROSS:=$(if $(and $(findstring w,$P),$(findstring Linux,$H)),x86_64-w64-mingw32-)
CC    ?= $(CROSS)gcc
CXX   ?= $(CROSS)g++
# LD    = $(CC)
NM    ?= $(CROSS)nm
DLLTOOL ?= $(CROSS)dlltool
MINGW_KAFKA_PKG=mingw-w64-x86_64-librdkafka-2.14.0-1-any.pkg.tar.zst
MINGW_KAFKA_DIR=tmp/mingw64

CPPFLAGS+=-DKXVER=3
WARNINGS=-Wall -Wextra -Werror -Wsign-compare -Wno-ignored-qualifiers -Wno-parentheses -Wno-strict-aliasing
CFLAGS+=-fPIC $(WARNINGS)

ifdef DEBUG
CFLAGS+=-g3 -O0 -fprofile-arcs -ftest-coverage -fno-inline
LDFLAGS+=--coverage
LDLIBS+=-lgcov
else
CFLAGS+=-O2 
endif
ifneq ($P,w)
LDLIBS+=-lz -lpthread -lssl
  ifdef STATIC
  LDLIBS+=$(KAFKA_ROOT)/lib/librdkafka.a
  else
  LDLIBS+=-lrdkafka
  endif
endif

ifeq ($P,l)
LDLIBS+=-lrt
endif

ifeq ($T,li64)
CFLAGS+=-include force_link_glibc_2.17.h -static-libgcc
endif

ifeq ($P,m)
OSMIN=-mmacosx-version-min=10.12
CFLAGS+=-Wno-pointer-sign $(OSMIN)
LDFLAGS+=-undefined dynamic_lookup -bundle $(OSMIN)
else
LDFLAGS+=-shared
endif

ifeq ($(QMOD),1)
TGT=clib.$T.$E
else
TGT=libkfk.$E
endif

all: $(TGT)

$(TGT): kfk.o
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS)

kfk.o: k.h

ifeq ($P,w)
CPPFLAGS+=-I$(MINGW_KAFKA_DIR)/include
$(TGT):libq.a $(MINGW_KAFKA_DIR)/lib/librdkafka.dll.a
kfk.o: $(MINGW_KAFKA_DIR)/include/librdkafka/rdkafka.h
LDLIBS+=-lws2_32
endif

k.h:
	curl -s -O -L https://github.com/KxSystems/kdb/raw/master/c/c/k.h

q.lib:
	wget -q https://github.com/KxSystems/kdb/raw/master/w64/q.lib

q.def:q.lib
	echo 'LIBRARY q.exe'>$@;echo EXPORTS>>$@; $(NM) -p $< | grep 'T [a-zA-Z]' | sed 's/0* T //' >>$@;echo vk >>$@

libq.a:q.def;$(DLLTOOL) -l $@ -d $<

$(MINGW_KAFKA_DIR)/lib/librdkafka.dll.a $(MINGW_KAFKA_DIR)/include/librdkafka/rdkafka.h:
	curl -LO https://mirror.msys2.org/mingw/mingw64/$(MINGW_KAFKA_PKG)
	mkdir -p tmp
	tar -xf $(MINGW_KAFKA_PKG) -C tmp

install: $(TGT)
ifeq ($(QMOD),1)
	mkdir -p $(PREFIX)/kafka
	cp $(TGT) $(PREFIX)/kafka
	cp kfk.q $(PREFIX)/kafka/init.q
else
	install $(TGT) $(QHOME)/$P64
endif

clean:
	rm -rf $(TGT) *.o $(PREFIX)/kafka
