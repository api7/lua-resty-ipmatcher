INST_PREFIX ?= /usr
INST_LIBDIR ?= $(INST_PREFIX)/lib/lua/5.1
INST_LUADIR ?= $(INST_PREFIX)/share/lua/5.1
INSTALL ?= install


.PHONY: test


### test:         Run test suite. Use test=... for specific tests
.PHONY: test
test:
	TEST_NGINX_LOG_LEVEL=info \
	prove -I../test-nginx/lib -r -s t/


### install:      Install the library to runtime
.PHONY: install
install:
	$(INSTALL) -d $(INST_LUADIR)/resty/
	$(INSTALL) resty/*.lua $(INST_LUADIR)/resty/
	$(INSTALL) $(C_SO_NAME) $(INST_LIBDIR)/


### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
