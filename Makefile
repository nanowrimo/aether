PREFIX ?= /usr/local

install :
	install -o root -m 755 bin/* "$(PREFIX)/bin"
	install -d -o root -m 755 "$(PREFIX)/lib/aether"
	find lib/aether -depth 1 -type f -not -name ".*" \
	  -exec install -o root -m 644 {} "$(PREFIX)/lib/aether" \;
	install -d -o root -m 755 "$(PREFIX)/lib/aether/prime"
	find lib/aether/prime -depth 1 -type f -not -name ".*" \
	  -exec install -o root -m 644 {} "$(PREFIX)/lib/aether/prime" \;
	install -d -o root -m 755 "$(PREFIX)/lib/aether/prime/remote"
	find lib/aether/prime/remote -depth 1 -type f -not -name ".*" \
	  -exec install -o root -m 755 {} "$(PREFIX)/lib/aether/prime/remote" \;
