.POSIX:
PREFIX = ~/.local
.PHONY: install uninstall
NAME = bat

$(NAME):
	cp awkat.sh $(NAME)

install: $(NAME)
	chmod 755 $(NAME)
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -vf $(NAME) ${DESTDIR}${PREFIX}/bin
uninstall:
	rm -vf ${DESTDIR}${PREFIX}/bin/bat
clean:
	rm -vrf $(NAME)

