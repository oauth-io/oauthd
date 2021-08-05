.PHONY: all install build \
				publish-prerelease prerelease-version \
				npm-publish

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

publish-prerelease: prerelease-version npm-publish-prerelease

prerelease-version:
	$(NPM) version prerelease --preid=$(PRERELEASE_ID)

npm-publish-prerelease:
	$(NPM) publish --tag=next

npm-publish:
	$(NPM) publish
