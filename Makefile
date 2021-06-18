.PHONY: all install build \
				publish-prerelease prerelease-version

all: build

NPM ?= npm
GRUNT ?= ./node_modules/.bin/grunt

install:
	$(NPM) install

build:
	$(GRUNT)

###################
# Release process #
###################

PRERELEASE_ID=rc

publish-prerelease: prerelease-version

prerelease-version:
	$(NPM) version prerelease --preid=$(PRERELEASE_ID)
