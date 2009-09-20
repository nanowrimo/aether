PREFIX ?= /usr/local

install :
	install -o root -m 755 bin/* "$(PREFIX)/bin"
	install -d -o root -m 755 "$(PREFIX)/lib/aether"
	install -o root -m 644 lib/aether/* "$(PREFIX)/lib/aether"
