# Makefile for D64QLPlugin
# written by Christian Vogelgsang <chris@vogelgsang.org>
#

PROJECT=D64QLPlugin
VERSION=0.2

DEVTOOLS=/Developer
XCODEBUILD=$(DEVTOOLS)/usr/bin/xcodebuild
RELEASE=build/Release
PLUGIN=$(RELEASE)/$(PROJECT).qlgenerator
DISTDIR=$(PROJECT)-$(VERSION)
BINDIR=$(DISTDIR)-bin
SRCDIR=$(DISTDIR)-src

.PHONY: all build clean dist bin-dist src-dist test

all: build

build:
	$(XCODEBUILD)

clean:
	$(XCODEBUILD) clean
	rm -rf $(BINDIR) $(SRCDIR)

dist: bin-dist src-dist

bin-dist: build
	rm -f $(BINDIR).zip
	rm -rf $(BINDIR)
	mkdir $(BINDIR)
	mv $(PLUGIN) $(BINDIR)
	cp README.txt $(BINDIR)
	cp font/CBM.dfont $(BINDIR)
	zip -r $(BINDIR).zip $(BINDIR)
	
src-dist:
	rm -f $(SRCDIR).zip
	rm -rf $(SRCDIR)
	svn export . $(SRCDIR)
	zip -r $(SRCDIR).zip $(SRCDIR)
	rm -rf $(SRCDIR)
	
test: build
	rm -rf ~/Library/QuickLook/$(PROJECT).qlgenerator
	mv $(PLUGIN) ~/Library/QuickLook/
	qlmanage -r
	qlmanage -m 2>&1 | grep $(PROJECT)

