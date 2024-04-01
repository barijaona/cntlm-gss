#
# You can tweak these three variables to make things install where you
# like, but do not touch more unless you know what you are doing. ;)
#
DESTDIR    	:= /usr/local
SYSCONFDIR 	:= $(DESTDIR)/etc
BINDIR     	:= $(DESTDIR)/bin
MANDIR     	:= $(DESTDIR)/share/man

#
# Careful now...
# __BSD_VISIBLE is for FreeBSD AF_* constants
# _ALL_SOURCE is for AIX 5.3 LOG_PERROR constant
#
NAME		:= cntlm
CC		:= gcc
VER		:= $(shell cat VERSION)
OS		:= $(shell uname -s)
OSLDFLAGS	:= $(shell [ $(OS) = "SunOS" ] && echo "-lrt -lsocket -lnsl")
LDFLAGS		:= -lpthread $(OSLDFLAGS)
CYGWIN_REQS	:= cygwin1.dll cyggcc_s-1.dll cygstdc++-6.dll cygrunsrv.exe 

ifeq ($(DEBUG),1)
	CFLAGS	+= -g  -std=c99 -Wall -pedantic -D__BSD_VISIBLE -D_ALL_SOURCE -D_XOPEN_SOURCE=600 -D_POSIX_C_SOURCE=200112 -D_ISOC99_SOURCE -D_REENTRANT -D_BSD_SOURCE -D_DEFAULT_SOURCE -D_DARWIN_C_SOURCE -DVERSION=\"'$(VER)'\"
else
	CFLAGS	+= -O3 -std=c99 -D__BSD_VISIBLE -D_ALL_SOURCE -D_XOPEN_SOURCE=600 -D_POSIX_C_SOURCE=200112 -D_ISOC99_SOURCE -D_REENTRANT -D_BSD_SOURCE -D_DEFAULT_SOURCE -D_DARWIN_C_SOURCE -DVERSION=\"'$(VER)'\"
endif

ifneq ($(findstring CYGWIN,$(OS)),)
	OBJS=utils.o ntlm.o xcrypt.o config.o socket.o acl.o auth.o http.o forward.o direct.o scanner.o pages.o main.o win/resources.o
else
	OBJS=utils.o ntlm.o xcrypt.o config.o socket.o acl.o auth.o http.o forward.o direct.o scanner.o pages.o main.o
endif

CONFIG_GSS=$(shell grep -c "config_gss 1" config/config.h)
ifeq ($(CONFIG_GSS),1)
	OBJS+=kerberos.o
ifeq ($(OS),Darwin)
	LDFLAGS+=-framework GSS
else
	LDFLAGS+=-lgssapi_krb5
 endif
endif

#CFLAGS+=-g

all: $(NAME)

$(NAME): configure-stamp $(OBJS)
	@echo "Linking $@"
	@$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)

main.o: main.c
	@echo "Compiling $<"
	@if [ -z "$(SYSCONFDIR)" ]; then \
		$(CC) $(CFLAGS) -c main.c -o $@; \
	else \
		$(CC) $(CFLAGS) -DSYSCONFDIR=\"$(SYSCONFDIR)\" -c main.c -o $@; \
	fi

%.o: %.c
	@echo "Compiling $<"
	@$(CC) $(CFLAGS) -c -o $@ $<

configure-stamp:
	./configure

win/resources.o: win/resources.rc
	@echo Win64: adding ICON resource
	@windres $^ -o $@

install: $(NAME)
	# Special handling for install(1)
	if [ "`uname -s`" = "AIX" ]; then \
		install -M 755 -S -f $(BINDIR) $(NAME); \
		install -M 644 -f $(MANDIR)/man1 doc/$(NAME).1; \
		install -M 600 -c $(SYSCONFDIR) doc/$(NAME).conf; \
	elif [ "`uname -s`" = "Darwin" ]; then \
		install -m 755 -s $(NAME) $(BINDIR)/$(NAME); \
		install -m 644 doc/$(NAME).1 $(MANDIR)/man1/$(NAME).1; \
		install -m 644 net.sourceforge.cntlm.plist \
		    /Library/LaunchAgents/net.sourceforge.cntlm.plist; \
		[ -f $(SYSCONFDIR)/$(NAME).conf -o -z "$(SYSCONFDIR)" ] \
			|| install -m 600 doc/$(NAME).conf $(SYSCONFDIR)/$(NAME).conf; \
	else \
		install -D -m 755 -s $(NAME) $(BINDIR)/$(NAME); \
		install -D -m 644 doc/$(NAME).1 $(MANDIR)/man1/$(NAME).1; \
		[ -f $(SYSCONFDIR)/$(NAME).conf -o -z "$(SYSCONFDIR)" ] \
			|| install -D -m 600 doc/$(NAME).conf $(SYSCONFDIR)/$(NAME).conf; \
	fi
	@echo; echo "Cntlm will look for configuration in $(SYSCONFDIR)/$(NAME).conf"

tgz:
	mkdir -p tmp
	rm -rf tmp/$(NAME)-$(VER)
	git checkout-index -a -f --prefix=./tmp/$(NAME)-$(VER)/
	tar zcvf $(NAME)-$(VER).tar.gz -C tmp/ $(NAME)-$(VER)
	rm -rf tmp/$(NAME)-$(VER)
	rmdir tmp 2>/dev/null || true

tbz2:
	mkdir -p tmp
	rm -rf tmp/$(NAME)-$(VER)
	git checkout-index -a -f --prefix=./tmp/$(NAME)-$(VER)/
	tar jcvf $(NAME)-$(VER).tar.bz2 -C tmp/ $(NAME)-$(VER)
	rm -rf tmp/$(NAME)-$(VER)
	rmdir tmp 2>/dev/null || true

deb:
	sed -i "s/^\(cntlm *\)([^)]*)/\1($(VER))/g" debian/changelog
	if [ `id -u` = 0 ]; then \
		debian/rules binary; \
		debian/rules clean; \
	else \
		fakeroot debian/rules binary; \
		fakeroot debian/rules clean; \
	fi
	mv ../cntlm_$(VER)*.deb .

rpm:
	sed -i "s/^\(Version:[\t ]*\)\(.*\)/\1$(VER)/g" rpm/cntlm.spec
	if [ `id -u` = 0 ]; then \
		rpm/rules binary; \
		rpm/rules clean; \
	else \
		fakeroot rpm/rules binary; \
		fakeroot rpm/rules clean; \
	fi

win: win/setup.iss $(NAME) win/cntlm_manual.pdf win/cntlm.ini win/LICENSE.txt $(NAME)-$(VER)-win64.exe $(NAME)-$(VER)-win64.zip

$(NAME)-$(VER)-win64.exe:
	@echo Win64: preparing binaries for GUI installer
	@cp $(patsubst %, /bin/%, $(CYGWIN_REQS)) win/
ifeq ($(DEBUG),1)
	@echo Win64: copy DEBUG executable
	@cp -p cntlm.exe win/
else
	@echo Win64: copy release executable
	@strip -o win/cntlm.exe cntlm.exe
endif
	@echo Win64: generating GUI installer
	@win/Inno5/ISCC.exe /Q win/setup.iss #/Q win/setup.iss

$(NAME)-$(VER)-win64.zip:
	@echo Win64: creating ZIP release for manual installs
	@ln -s win $(NAME)-$(VER)
	zip -9 $@ $(patsubst %, $(NAME)-$(VER)/%, cntlm.exe $(CYGWIN_REQS) cntlm.ini LICENSE.txt cntlm_manual.pdf) 
	@rm -f $(NAME)-$(VER)

win/cntlm.ini: doc/cntlm.conf
	@cat doc/cntlm.conf | unix2dos > $@

win/LICENSE.txt: COPYRIGHT LICENSE
	@cat COPYRIGHT LICENSE | unix2dos > $@

win/cntlm_manual.pdf: doc/cntlm.1
	@echo Win64: generating PDF manual
	@rm -f $@
	@groff -t -e -mandoc -Tps doc/cntlm.1 | ps2pdf - $@

win/setup.iss: win/setup.iss.in
ifeq ($(findstring CYGWIN,$(OS)),)
	@echo
	@echo "* This build target must be run from a Cywgin shell on Windows *"
	@echo
	@exit 1
endif
	@sed "s/\$$VERSION/$(VER)/g" $^ > $@

uninstall:
	rm -f $(BINDIR)/$(NAME) $(MANDIR)/man1/$(NAME).1 2>/dev/null || true

clean:
	@rm -f config/endian config/gethostname config/socklen_t config/strdup config/arc4random_buf config/strlcat config/strlcpy config/memset_s config/gss config/*.exe
	@rm -f *.o cntlm cntlm.exe configure-stamp build-stamp config/config.h
	@rm -f $(patsubst %, win/%, $(CYGWIN_REQS) cntlm.exe cntlm.ini LICENSE.txt resources.o setup.iss cntlm_manual.pdf)
	@if [ -h Makefile ]; then rm -f Makefile; mv Makefile.gcc Makefile; fi

distclean: clean
ifeq ($(findstring CYGWIN,$(OS)),)
	if [ `id -u` = 0 ]; then \
		debian/rules clean; \
		rpm/rules clean; \
	else \
		fakeroot debian/rules clean; \
		fakeroot rpm/rules clean; \
	fi
endif
	@rm -f *.exe *.deb *.rpm *.tgz *.tar.gz *.tar.bz2 *.zip *.exe tags ctags pid 2>/dev/null

.PHONY: all install tgz tbz2 deb rpm win uninstall clean distclean
