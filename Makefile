.PHONY: all install build

all: build

NPM ?= npm
GRUNT ?= ./node_modules/.bin/grunt

install:
	$(NPM) install

build:
	$(GRUNT)
