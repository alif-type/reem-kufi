VERSION=0.8
NAME=ReemKufi
LATIN=JosefinSans

DIST=$(NAME)-$(VERSION)

BUILDDIR=build
TOOLDIR=tools

PYTHON ?= python3

PREPARE=$(TOOLDIR)/prepare.py
MKUFO=$(TOOLDIR)/mkufo.py

FONTS=Regular

UFO=$(FONTS:%=$(BUILDDIR)/$(NAME)-%.ufo)
OTF=$(FONTS:%=$(NAME)-%.otf)
TTF=$(FONTS:%=$(NAME)-%.ttf)
SVG=Sample.svg

export SOURCE_DATE_EPOCH ?= 0

define generate_fonts
mkdir -p $(BUILDDIR)
pushd $(BUILDDIR) 1>/dev/null;                                                 \
PYTHONPATH=$(3):${PYTHONMATH}                                                  \
fontmake --ufo $(abspath $(2))                                                 \
         --output $(1)                                                         \
         --verbose WARNING                                                     \
         --feature-writer KernFeatureWriter                                    \
         --feature-writer markFeatureWriter::MarkFeatureWriter                 \
         --subroutinizer cffsubr                                               \
         --overlaps-backend pathops                                            \
         ;                                                                     \
popd 1>/dev/null
endef

all: otf doc

otf: $(OTF)
ttf: $(TTF)
ufo: $(UFO)
doc: $(SVG)

SHELL=/usr/bin/env bash

.PRECIOUS: $(BUILDDIR)/master_otf/$(NAME)-%.otf $(BUILDDIR)/master_ttf/$(NAME)-%.ttf $(BUILDDIR)/$(LATIN)-%.ufo

$(NAME)-%.otf: $(BUILDDIR)/master_otf/$(NAME)-%.otf
	@cp $< $@

$(NAME)-%.ttf: $(BUILDDIR)/master_ttf/$(NAME)-%.ttf
	@cp $< $@

$(BUILDDIR)/master_otf/$(NAME)-%.otf: $(UFO)
	@echo "   MAKE	$(@F)"
	@$(call generate_fonts,otf,$<,$(abspath $(TOOLDIR)))

$(BUILDDIR)/master_ttf/$(NAME)-%.ttf: $(UFO)
	@echo "   MAKE	$(@F)"
	@$(call generate_fonts,ttf,$<,$(abspath $(TOOLDIR)))

$(BUILDDIR)/$(LATIN)-%.ufo: $(LATIN).glyphs
	@echo "   GEN	$(@F)"
	@$(PYTHON) $(MKUFO) --out-file=$@ $<

$(BUILDDIR)/$(NAME)-%.pre.ufo: $(NAME).glyphs
	@echo "   GEN	$(@F)"
	@$(PYTHON) $(MKUFO) --out-file=$@ $<

$(BUILDDIR)/$(NAME)-%.ufo: $(BUILDDIR)/$(NAME)-%.pre.ufo $(BUILDDIR)/$(LATIN)-%.ufo
	@echo "   GEN	$(@F)"
	@$(PYTHON) $(PREPARE) --version=$(VERSION) --out-file=$@ $< $(word 2,$+)

$(SVG): $(NAME)-Regular.otf
	@echo "   GEN	$(@F)"
	@hb-view --font-file=$< \
		 --output-file=$@ \
		 --text="ريم على القــاع بين البــان و العـلم   أحل سفك دمي في الأشهر الحرم" \
		 --features="+cv01,-cv01[6],-cv01[32:36],+cv02[40],-cv01[45]"

dist: ttf
	@mkdir -p $(NAME)-$(VERSION)/ttf
	@cp $(OTF) $(NAME)-$(VERSION)
	@cp $(TTF) $(NAME)-$(VERSION)/ttf
	@cp OFL.txt $(NAME)-$(VERSION)
	@sed -e "/^!\[Sample\].*./d" README.md > $(NAME)-$(VERSION)/README.txt
	@zip -r $(NAME)-$(VERSION).zip $(NAME)-$(VERSION)

clean:
	@rm -rf $(OTF) $(TTF) $(SVG) $(BUILDDIR) $(NAME)-$(VERSION) $(NAME)-$(VERSION).zip
