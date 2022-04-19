VERSION := 1.0.0

# install directory layout
PREFIX ?= /usr/local
INCLUDEDIR ?= $(PREFIX)/include
LIBDIR ?= $(PREFIX)/lib
PCLIBDIR ?= $(LIBDIR)/pkgconfig

# collect typescript C++ sources, and link if necessary
CPPSRCTYPES := $(wildcard typescript/src/*.cc)

# collect typescript sources
SRCTYPES := $(wildcard typescript/src/*.c)
SRCTYPES += $(CPPSRCTYPES)
OBJTYPES := $(addsuffix .o,$(basename $(SRCTYPES)))

# collect tsx C++ sources, and link if necessary
CPPSRCTSX := $(wildcard tsx/src/*.cc)

# collect tsx sources
SRCTSX := $(wildcard tsx/src/*.c)
SRCTSX += $(CPPSRCTSX)
OBJTSX := $(addsuffix .o,$(basename $(SRCTSX)))

# ABI versioning
SONAME_MAJOR := 0
SONAME_MINOR := 0

CFLAGS ?= -O3 -Wall -Wextra
CXXFLAGS ?= -O3 -Wall -Wextra
override CFLAGS += -std=gnu99 -fPIC
override CXXFLAGS += -fPIC

# OS-specific bits
ifeq ($(shell uname),Darwin)
	SOEXT = dylib
	SOEXTVER_MAJOR = $(SONAME_MAJOR).dylib
	SOEXTVER = $(SONAME_MAJOR).$(SONAME_MINOR).dylib
	LINKSHAREDTYPES += -dynamiclib -Wl,-install_name,$(LIBDIR)/libtree-sitter-typescript.$(SONAME_MAJOR).dylib
	LINKSHAREDTSX += -dynamiclib -Wl,-install_name,$(LIBDIR)/libtree-sitter-tsx.$(SONAME_MAJOR).dylib
else
	SOEXT = so
	SOEXTVER_MAJOR = so.$(SONAME_MAJOR)
	SOEXTVER = so.$(SONAME_MAJOR).$(SONAME_MINOR)
	LINKSHAREDTYPES += -shared -Wl,-soname,libtree-sitter-typescript.so.$(SONAME_MAJOR)
	LINKSHAREDTSX += -shared -Wl,-soname,libtree-sitter-tsx.so.$(SONAME_MAJOR)
endif
ifneq (,$(filter $(shell uname),FreeBSD NetBSD DragonFly))
	PCLIBDIR := $(PREFIX)/libdata/pkgconfig
endif

all: libtree-sitter-typescript.a libtree-sitter-typescript.$(SOEXTVER) libtree-sitter-tsx.a libtree-sitter-tsx.$(SOEXTVER)

libtree-sitter-typescript.a: $(OBJTYPES)
	$(AR) rcs $@ $^

libtree-sitter-typescript.$(SOEXTVER): $(OBJTYPES)
	$(CC) $(LDFLAGS) $(LINKSHAREDTYPES) $^ $(LDLIBS) -o $@
	ln -sf $@ libtree-sitter-typescript.$(SOEXT)
	ln -sf $@ libtree-sitter-typescript.$(SOEXTVER_MAJOR)

libtree-sitter-tsx.a: $(OBJTSX)
	$(AR) rcs $@ $^

libtree-sitter-tsx.$(SOEXTVER): $(OBJTSX)
	$(CC) $(LDFLAGS) $(LINKSHAREDTSX) $^ $(LDLIBS) -o $@
	ln -sf $@ libtree-sitter-tsx.$(SOEXT)
	ln -sf $@ libtree-sitter-tsx.$(SOEXTVER_MAJOR)

install: all
	install -d '$(DESTDIR)$(LIBDIR)'
	install -m755 libtree-sitter-typescript.a '$(DESTDIR)$(LIBDIR)'/libtree-sitter-typescript.a
	install -m755 libtree-sitter-typescript.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-typescript.$(SOEXTVER)
	ln -sf libtree-sitter-typescript.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-typescript.$(SOEXTVER_MAJOR)
	ln -sf libtree-sitter-typescript.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-typescript.$(SOEXT)
	install -m755 libtree-sitter-tsx.a '$(DESTDIR)$(LIBDIR)'/libtree-sitter-tsx.a
	install -m755 libtree-sitter-tsx.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-tsx.$(SOEXTVER)
	ln -sf libtree-sitter-tsx.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-tsx.$(SOEXTVER_MAJOR)
	ln -sf libtree-sitter-tsx.$(SOEXTVER) '$(DESTDIR)$(LIBDIR)'/libtree-sitter-tsx.$(SOEXT)
	install -d '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter
	install -m644 bindings/c/typescript.h '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/
	install -m644 bindings/c/tsx.h '$(DESTDIR)$(INCLUDEDIR)'/tree_sitter/
	install -d '$(DESTDIR)$(PCLIBDIR)'
	sed -e 's|@LIBDIR@|$(LIBDIR)|;s|@INCLUDEDIR@|$(INCLUDEDIR)|;s|@VERSION@|$(VERSION)|' \
	    -e 's|=$(PREFIX)|=$${prefix}|' \
	    -e 's|@PREFIX@|$(PREFIX)|' \
	    -e 's|@ADDITIONALLIBS@|$(ADDITIONALLIBS)|' \
	    bindings/c/tree-sitter-typescript.pc.in > '$(DESTDIR)$(PCLIBDIR)'/tree-sitter-typescript.pc
	sed -e 's|@LIBDIR@|$(LIBDIR)|;s|@INCLUDEDIR@|$(INCLUDEDIR)|;s|@VERSION@|$(VERSION)|' \
		-e 's|=$(PREFIX)|=$${prefix}|' \
		-e 's|@PREFIX@|$(PREFIX)|' \
		-e 's|@ADDITIONALLIBS@|$(ADDITIONALLIBS)|' \
		bindings/c/tree-sitter-tsx.pc.in > '$(DESTDIR)$(PCLIBDIR)'/tree-sitter-tsx.pc

clean:
	rm -f $(OBJTYPES) libtree-sitter-typescript.a libtree-sitter-typescript.$(SOEXT) libtree-sitter-typescript.$(SOEXTVER_MAJOR) libtree-sitter-typescript.$(SOEXTVER)
	rm -f $(OBJTSX) libtree-sitter-tsx.a libtree-sitter-tsx.$(SOEXT) libtree-sitter-tsx.$(SOEXTVER_MAJOR) libtree-sitter-tsx.$(SOEXTVER)

.PHONY: all install clean
