PREFIX ?= /usr/local

install :
	install -o root -m 755 bin/* "$(PREFIX)/bin"
	install -d -o root -m 755 "$(PREFIX)/lib/aether"
	find lib/ -mindepth 1 -maxdepth 1 -type f -not -name ".*" \
	  -exec install -o root -m 644 {} "$(PREFIX)/lib" \;
	find lib/aether -mindepth 1 -maxdepth 1 -type f -not -name ".*" \
	  -exec install -o root -m 644 {} "$(PREFIX)/lib/aether" \;
	install -d -o root -m 755 "$(PREFIX)/lib/aether/prime"
	find lib/aether/prime -mindepth 1 -maxdepth 1 -type f -not -name ".*" \
	  -exec install -o root -m 644 {} "$(PREFIX)/lib/aether/prime" \;
	install -d -o root -m 755 "$(PREFIX)/lib/aether/prime/remote"
	find lib/aether/prime/remote -mindepth 1 -maxdepth 1 -type f \
	  -not -name ".*" \
	  -exec install -o root -m 755 {} "$(PREFIX)/lib/aether/prime/remote" \;
	install -d -o root -m 755 "$(PREFIX)/lib/aether/instance"
	find lib/aether/instance -mindepth 1 -maxdepth 1 -type f \
	  -not -name ".*" \
	  -exec install -o root -m 755 {} "$(PREFIX)/lib/aether/instance" \;
	install -d -o root -m 755 "$(PREFIX)/lib/aether/instance_helpers"
	find lib/aether/instance_helpers -mindepth 1 -maxdepth 1 -type f \
	  -not -name ".*" \
	  -exec install -o root -m 755 {} "$(PREFIX)/lib/aether/instance_helpers" \;
	install -d -o root -m 755 "$(PREFIX)/lib/aether/instance_promoter"
	find lib/aether/instance_promoter -mindepth 1 -maxdepth 1 -type f \
	  -not -name ".*" \
	  -exec install -o root -m 755 {} "$(PREFIX)/lib/aether/instance_promoter" \;
	install -d -o root -m 755 "$(PREFIX)/lib/aether/shell"
	find lib/aether/shell -mindepth 1 -maxdepth 1 -type f \
	  -not -name ".*" \
	  -exec install -o root -m 755 {} "$(PREFIX)/lib/aether/shell" \;
	install -d -o root -m 755 "$(PREFIX)/lib/aether/snapshot"
	find lib/aether/snapshot -mindepth 1 -maxdepth 1 -type f \
	  -not -name ".*" \
	  -exec install -o root -m 755 {} "$(PREFIX)/lib/aether/snapshot" \;
