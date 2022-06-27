.POSIX:
PREFIX = ~/.local
.PHONY: install uninstall
install:
	chmod 755 bat
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -vf bat ${DESTDIR}${PREFIX}/bin
uninstall:
	rm -vf ${DESTDIR}${PREFIX}/bin/bat

