# List all targets with 'make list'
SRCDIR   := $(abspath $(lastword $(MAKEFILE_LIST))/..)
FONTDIR  := build/fonts
UFODIR   := build/ufo
BIN      := $(SRCDIR)/build/venv/bin
VENV     := build/venv/bin/activate
VERSION  := $(shell cat version.txt)
MAKEFILE := $(lastword $(MAKEFILE_LIST))

export PATH := $(BIN):$(PATH)

default: all

# ---------------------------------------------------------------------------------
# intermediate sources

$(UFODIR)/%.glyphs: src/%.glyphspackage | $(UFODIR) venv
	. $(VENV) ; build/venv/bin/glyphspkg -o $(dir $@) $^

# features
src/features: $(wildcard src/features/*)
	@touch "$@"
	@true
$(UFODIR)/features: src/features
	@mkdir -p $(UFODIR)
	@rm -f $(UFODIR)/features
	@ln -s ../../src/features $(UFODIR)/features

# designspace
$(UFODIR)/%.designspace: $(UFODIR)/%.glyphs $(UFODIR)/features | venv
	. $(VENV) ; fontmake -o ufo -g $< --designspace-path $@ \
		--master-dir $(UFODIR) --instance-dir $(UFODIR)
	. $(VENV) ; python misc/tools/postprocess-designspace.py $@

# UFOs from designspace
$(UFODIR)/Inter-%Italic.ufo: $(UFODIR)/Inter2-Italic.designspace | venv
	. $(VENV) ; bash misc/tools/gen-instance-ufo.sh $< $@
$(UFODIR)/Inter-%.ufo: $(UFODIR)/Inter2-Roman.designspace | venv
	. $(VENV) ; bash misc/tools/gen-instance-ufo.sh $< $@

# make sure intermediate files are not rm'd by make
.PRECIOUS: \
	$(UFODIR)/Inter2-Black.ufo \
	$(UFODIR)/Inter2-Regular.ufo \
	$(UFODIR)/Inter2-Thin.ufo \
	$(UFODIR)/Inter2-Light.ufo \
	$(UFODIR)/Inter2-ExtraLight.ufo \
	$(UFODIR)/Inter2-Medium.ufo \
	$(UFODIR)/Inter2-SemiBold.ufo \
	$(UFODIR)/Inter2-Bold.ufo \
	$(UFODIR)/Inter2-ExtraBold.ufo \
	\
	$(UFODIR)/Inter2-BlackItalic.ufo \
	$(UFODIR)/Inter2-Italic.ufo \
	$(UFODIR)/Inter2-ThinItalic.ufo \
	$(UFODIR)/Inter2-LightItalic.ufo \
	$(UFODIR)/Inter2-ExtraLightItalic.ufo \
	$(UFODIR)/Inter2-MediumItalic.ufo \
	$(UFODIR)/Inter2-SemiBoldItalic.ufo \
	$(UFODIR)/Inter2-BoldItalic.ufo \
	$(UFODIR)/Inter2-ExtraBoldItalic.ufo \
	\
	$(UFODIR)/Inter2-DisplayBlack.ufo \
	$(UFODIR)/Inter2-Display.ufo \
	$(UFODIR)/Inter2-DisplayThin.ufo \
	$(UFODIR)/Inter2-DisplayLight.ufo \
	$(UFODIR)/Inter2-DisplayExtraLight.ufo \
	$(UFODIR)/Inter2-DisplayMedium.ufo \
	$(UFODIR)/Inter2-DisplaySemiBold.ufo \
	$(UFODIR)/Inter2-DisplayBold.ufo \
	$(UFODIR)/Inter2-DisplayExtraBold.ufo \
	\
	$(UFODIR)/Inter2-DisplayBlackItalic.ufo \
	$(UFODIR)/Inter2-DisplayItalic.ufo \
	$(UFODIR)/Inter2-DisplayThinItalic.ufo \
	$(UFODIR)/Inter2-DisplayLightItalic.ufo \
	$(UFODIR)/Inter2-DisplayExtraLightItalic.ufo \
	$(UFODIR)/Inter2-DisplayMediumItalic.ufo \
	$(UFODIR)/Inter2-DisplaySemiBoldItalic.ufo \
	$(UFODIR)/Inter2-DisplayBoldItalic.ufo \
	$(UFODIR)/Inter2-DisplayExtraBoldItalic.ufo \
	\
	$(UFODIR)/Inter2-Roman.glyphs \
	$(UFODIR)/Inter2-Italic.glyphs \
	$(UFODIR)/Inter2-Roman.designspace \
	$(UFODIR)/Inter2-Italic.designspace

# ---------------------------------------------------------------------------------
# products

$(FONTDIR)/static/%.otf: $(UFODIR)/%.ufo | $(FONTDIR)/static venv
	. $(VENV) ; fontmake -u $< -o otf --output-path $@ --overlaps-backend pathops --production-names

$(FONTDIR)/static/%.ttf: $(UFODIR)/%.ufo | $(FONTDIR)/static venv
	. $(VENV) ; fontmake -u $< -o ttf --output-path $@ --overlaps-backend pathops --production-names

$(FONTDIR)/static-hinted/%.ttf: $(FONTDIR)/static/%.ttf | $(FONTDIR)/static-hinted venv
	. $(VENV) ; python -m ttfautohint --no-info "$<" "$@"

$(FONTDIR)/var/_%.var.ttf: $(UFODIR)/%.designspace | $(FONTDIR)/var venv
	. $(VENV) ; fontmake -o variable -m $< --output-path $@ \
	              --overlaps-backend pathops --production-names

$(FONTDIR)/var/_%.var.otf: $(UFODIR)/%.designspace | $(FONTDIR)/var venv
	. $(VENV) ; fontmake -o variable-cff2 -m $< --output-path $@ \
	              --overlaps-backend pathops --production-names

%.woff2: %.ttf | venv
	. $(VENV) ; misc/tools/woff2 compress -o "$@" "$<"

$(FONTDIR)/static:
	mkdir -p $@
$(FONTDIR)/static-hinted:
	mkdir -p $@
$(FONTDIR)/var:
	mkdir -p $@
$(UFODIR):
	mkdir -p $@

# roman + italic with STAT
$(FONTDIR)/var/inter-roman-and-italic.stamp: \
	  $(FONTDIR)/var/_Inter-Roman.var.ttf \
	  $(FONTDIR)/var/_Inter-Italic.var.ttf \
	  | venv
	@#. $(VENV) ; python misc/tools/postprocess-vf2.py $^
	mkdir $(FONTDIR)/var/gen-stat
	. $(VENV) ; gftools gen-stat --out $(FONTDIR)/var/gen-stat $^
	mv $(FONTDIR)/var/gen-stat/_Inter-Roman.var.ttf $(FONTDIR)/var/Inter.var.ttf
	mv $(FONTDIR)/var/gen-stat/_Inter-Italic.var.ttf $(FONTDIR)/var/Inter-Italic.var.ttf
	rm -rf $(FONTDIR)/var/gen-stat
	touch $@

$(FONTDIR)/var/Inter.var.ttf: $(FONTDIR)/var/inter-roman-and-italic.stamp
	touch $@
$(FONTDIR)/var/Inter-Italic.var.ttf: $(FONTDIR)/var/inter-roman-and-italic.stamp
	touch $@

$(FONTDIR)/var/InterV.var.ttf: $(FONTDIR)/var/Inter.var.ttf | venv
	. $(VENV) ; python misc/tools/rename.py --family "Inter V" -o $@ $<
$(FONTDIR)/var/InterV-Italic.var.ttf: $(FONTDIR)/var/Inter-Italic.var.ttf | venv
	. $(VENV) ; python misc/tools/rename.py --family "Inter V" -o $@ $<

var: \
	$(FONTDIR)/var/Inter.var.ttf \
	$(FONTDIR)/var/Inter-Italic.var.ttf \
	$(FONTDIR)/var/InterV.var.ttf \
	$(FONTDIR)/var/InterV-Italic.var.ttf

var_web: \
	$(FONTDIR)/var/Inter.var.woff2 \
	$(FONTDIR)/var/Inter-Italic.var.woff2

web: var_web static_web

static_otf: \
	$(FONTDIR)/static/Inter2-Black.otf \
	$(FONTDIR)/static/Inter2-BlackItalic.otf \
	$(FONTDIR)/static/Inter2-Regular.otf \
	$(FONTDIR)/static/Inter2-Italic.otf \
	$(FONTDIR)/static/Inter2-Thin.otf \
	$(FONTDIR)/static/Inter2-ThinItalic.otf \
	$(FONTDIR)/static/Inter2-Light.otf \
	$(FONTDIR)/static/Inter2-LightItalic.otf \
	$(FONTDIR)/static/Inter2-ExtraLight.otf \
	$(FONTDIR)/static/Inter2-ExtraLightItalic.otf \
	$(FONTDIR)/static/Inter2-Medium.otf \
	$(FONTDIR)/static/Inter2-MediumItalic.otf \
	$(FONTDIR)/static/Inter2-SemiBold.otf \
	$(FONTDIR)/static/Inter2-SemiBoldItalic.otf \
	$(FONTDIR)/static/Inter2-Bold.otf \
	$(FONTDIR)/static/Inter2-BoldItalic.otf \
	$(FONTDIR)/static/Inter2-ExtraBold.otf \
	$(FONTDIR)/static/Inter2-ExtraBoldItalic.otf \
	$(FONTDIR)/static/Inter2-DisplayBlack.otf \
	$(FONTDIR)/static/Inter2-DisplayBlackItalic.otf \
	$(FONTDIR)/static/Inter2-Display.otf \
	$(FONTDIR)/static/Inter2-DisplayItalic.otf \
	$(FONTDIR)/static/Inter2-DisplayThin.otf \
	$(FONTDIR)/static/Inter2-DisplayThinItalic.otf \
	$(FONTDIR)/static/Inter2-DisplayLight.otf \
	$(FONTDIR)/static/Inter2-DisplayLightItalic.otf \
	$(FONTDIR)/static/Inter2-DisplayExtraLight.otf \
	$(FONTDIR)/static/Inter2-DisplayExtraLightItalic.otf \
	$(FONTDIR)/static/Inter2-DisplayMedium.otf \
	$(FONTDIR)/static/Inter2-DisplayMediumItalic.otf \
	$(FONTDIR)/static/Inter2-DisplaySemiBold.otf \
	$(FONTDIR)/static/Inter2-DisplaySemiBoldItalic.otf \
	$(FONTDIR)/static/Inter2-DisplayBold.otf \
	$(FONTDIR)/static/Inter2-DisplayBoldItalic.otf \
	$(FONTDIR)/static/Inter2-DisplayExtraBold.otf \
	$(FONTDIR)/static/Inter2-DisplayExtraBoldItalic.otf

static_ttf: \
	$(FONTDIR)/static/Inter2-Black.ttf \
	$(FONTDIR)/static/Inter2-BlackItalic.ttf \
	$(FONTDIR)/static/Inter2-Regular.ttf \
	$(FONTDIR)/static/Inter2-Italic.ttf \
	$(FONTDIR)/static/Inter2-Thin.ttf \
	$(FONTDIR)/static/Inter2-ThinItalic.ttf \
	$(FONTDIR)/static/Inter2-Light.ttf \
	$(FONTDIR)/static/Inter2-LightItalic.ttf \
	$(FONTDIR)/static/Inter2-ExtraLight.ttf \
	$(FONTDIR)/static/Inter2-ExtraLightItalic.ttf \
	$(FONTDIR)/static/Inter2-Medium.ttf \
	$(FONTDIR)/static/Inter2-MediumItalic.ttf \
	$(FONTDIR)/static/Inter2-SemiBold.ttf \
	$(FONTDIR)/static/Inter2-SemiBoldItalic.ttf \
	$(FONTDIR)/static/Inter2-Bold.ttf \
	$(FONTDIR)/static/Inter2-BoldItalic.ttf \
	$(FONTDIR)/static/Inter2-ExtraBold.ttf \
	$(FONTDIR)/static/Inter2-ExtraBoldItalic.ttf \
	$(FONTDIR)/static/Inter2-DisplayBlack.ttf \
	$(FONTDIR)/static/Inter2-DisplayBlackItalic.ttf \
	$(FONTDIR)/static/Inter2-Display.ttf \
	$(FONTDIR)/static/Inter2-DisplayItalic.ttf \
	$(FONTDIR)/static/Inter2-DisplayThin.ttf \
	$(FONTDIR)/static/Inter2-DisplayThinItalic.ttf \
	$(FONTDIR)/static/Inter2-DisplayLight.ttf \
	$(FONTDIR)/static/Inter2-DisplayLightItalic.ttf \
	$(FONTDIR)/static/Inter2-DisplayExtraLight.ttf \
	$(FONTDIR)/static/Inter2-DisplayExtraLightItalic.ttf \
	$(FONTDIR)/static/Inter2-DisplayMedium.ttf \
	$(FONTDIR)/static/Inter2-DisplayMediumItalic.ttf \
	$(FONTDIR)/static/Inter2-DisplaySemiBold.ttf \
	$(FONTDIR)/static/Inter2-DisplaySemiBoldItalic.ttf \
	$(FONTDIR)/static/Inter2-DisplayBold.ttf \
	$(FONTDIR)/static/Inter2-DisplayBoldItalic.ttf \
	$(FONTDIR)/static/Inter2-DisplayExtraBold.ttf \
	$(FONTDIR)/static/Inter2-DisplayExtraBoldItalic.ttf

static_ttf_hinted: \
	$(FONTDIR)/static-hinted/Inter2-Black.ttf \
	$(FONTDIR)/static-hinted/Inter2-BlackItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-Regular.ttf \
	$(FONTDIR)/static-hinted/Inter2-Italic.ttf \
	$(FONTDIR)/static-hinted/Inter2-Thin.ttf \
	$(FONTDIR)/static-hinted/Inter2-ThinItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-Light.ttf \
	$(FONTDIR)/static-hinted/Inter2-LightItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-ExtraLight.ttf \
	$(FONTDIR)/static-hinted/Inter2-ExtraLightItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-Medium.ttf \
	$(FONTDIR)/static-hinted/Inter2-MediumItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-SemiBold.ttf \
	$(FONTDIR)/static-hinted/Inter2-SemiBoldItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-Bold.ttf \
	$(FONTDIR)/static-hinted/Inter2-BoldItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-ExtraBold.ttf \
	$(FONTDIR)/static-hinted/Inter2-ExtraBoldItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayBlack.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayBlackItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-Display.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayThin.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayThinItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayLight.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayLightItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayExtraLight.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayExtraLightItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayMedium.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayMediumItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplaySemiBold.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplaySemiBoldItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayBold.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayBoldItalic.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayExtraBold.ttf \
	$(FONTDIR)/static-hinted/Inter2-DisplayExtraBoldItalic.ttf

static_web: \
	$(FONTDIR)/static/Inter2-Black.woff2 \
	$(FONTDIR)/static/Inter2-BlackItalic.woff2 \
	$(FONTDIR)/static/Inter2-Regular.woff2 \
	$(FONTDIR)/static/Inter2-Italic.woff2 \
	$(FONTDIR)/static/Inter2-Thin.woff2 \
	$(FONTDIR)/static/Inter2-ThinItalic.woff2 \
	$(FONTDIR)/static/Inter2-Light.woff2 \
	$(FONTDIR)/static/Inter2-LightItalic.woff2 \
	$(FONTDIR)/static/Inter2-ExtraLight.woff2 \
	$(FONTDIR)/static/Inter2-ExtraLightItalic.woff2 \
	$(FONTDIR)/static/Inter2-Medium.woff2 \
	$(FONTDIR)/static/Inter2-MediumItalic.woff2 \
	$(FONTDIR)/static/Inter2-SemiBold.woff2 \
	$(FONTDIR)/static/Inter2-SemiBoldItalic.woff2 \
	$(FONTDIR)/static/Inter2-Bold.woff2 \
	$(FONTDIR)/static/Inter2-BoldItalic.woff2 \
	$(FONTDIR)/static/Inter2-ExtraBold.woff2 \
	$(FONTDIR)/static/Inter2-ExtraBoldItalic.woff2 \
	$(FONTDIR)/static/Inter2-DisplayBlack.woff2 \
	$(FONTDIR)/static/Inter2-DisplayBlackItalic.woff2 \
	$(FONTDIR)/static/Inter2-Display.woff2 \
	$(FONTDIR)/static/Inter2-DisplayItalic.woff2 \
	$(FONTDIR)/static/Inter2-DisplayThin.woff2 \
	$(FONTDIR)/static/Inter2-DisplayThinItalic.woff2 \
	$(FONTDIR)/static/Inter2-DisplayLight.woff2 \
	$(FONTDIR)/static/Inter2-DisplayLightItalic.woff2 \
	$(FONTDIR)/static/Inter2-DisplayExtraLight.woff2 \
	$(FONTDIR)/static/Inter2-DisplayExtraLightItalic.woff2 \
	$(FONTDIR)/static/Inter2-DisplayMedium.woff2 \
	$(FONTDIR)/static/Inter2-DisplayMediumItalic.woff2 \
	$(FONTDIR)/static/Inter2-DisplaySemiBold.woff2 \
	$(FONTDIR)/static/Inter2-DisplaySemiBoldItalic.woff2 \
	$(FONTDIR)/static/Inter2-DisplayBold.woff2 \
	$(FONTDIR)/static/Inter2-DisplayBoldItalic.woff2 \
	$(FONTDIR)/static/Inter2-DisplayExtraBold.woff2 \
	$(FONTDIR)/static/Inter2-DisplayExtraBoldItalic.woff2

static_web_hinted: \
	$(FONTDIR)/static-hinted/Inter2-Black.woff2 \
	$(FONTDIR)/static-hinted/Inter2-BlackItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-Regular.woff2 \
	$(FONTDIR)/static-hinted/Inter2-Italic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-Thin.woff2 \
	$(FONTDIR)/static-hinted/Inter2-ThinItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-Light.woff2 \
	$(FONTDIR)/static-hinted/Inter2-LightItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-ExtraLight.woff2 \
	$(FONTDIR)/static-hinted/Inter2-ExtraLightItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-Medium.woff2 \
	$(FONTDIR)/static-hinted/Inter2-MediumItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-SemiBold.woff2 \
	$(FONTDIR)/static-hinted/Inter2-SemiBoldItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-Bold.woff2 \
	$(FONTDIR)/static-hinted/Inter2-BoldItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-ExtraBold.woff2 \
	$(FONTDIR)/static-hinted/Inter2-ExtraBoldItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayBlack.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayBlackItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-Display.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayThin.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayThinItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayLight.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayLightItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayExtraLight.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayExtraLightItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayMedium.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayMediumItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplaySemiBold.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplaySemiBoldItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayBold.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayBoldItalic.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayExtraBold.woff2 \
	$(FONTDIR)/static-hinted/Inter2-DisplayExtraBoldItalic.woff2


all: var web static_otf static_ttf static_ttf_hinted

.PHONY: all var var_web static_otf static_ttf static_ttf_hinted static_web static_web_hinted \
        var_web web

# ---------------------------------------------------------------------------------
# testing

test: build/fontbakery-report-var.txt \
      build/fontbakery-report-static.txt

# FBAKE_ARGS are common args for all fontbakery targets
FBAKE_ARGS := check-universal \
              --no-colors \
              --no-progress \
              --loglevel WARN \
              --succinct \
              --full-lists \
              -j \
              -x com.google.fonts/check/family/win_ascent_and_descent

build/fontbakery-report-var.txt: \
		$(FONTDIR)/var/Inter.var.ttf \
		$(FONTDIR)/var/Inter-Italic.var.ttf \
		| venv
	@echo "fontbakery {Inter,Inter-Italic}.var.ttf > $(@) ..."
	@. $(VENV) ; fontbakery \
		$(FBAKE_ARGS) -x com.google.fonts/check/STAT_strings \
		$^ > $@ \
		|| (cat $@; echo "report at $@"; touch -m -t 199001010000 $@; exit 1)

build/fontbakery-report-static.txt: $(wildcard $(FONTDIR)/static/Inter2-*.otf) | venv
	@echo "fontbakery static/Inter2-*.otf > $(@) ..."
	@. $(VENV) ; fontbakery \
		$(FBAKE_ARGS) -x com.google.fonts/check/family/underline_thickness \
		$^ > $@ \
		|| (cat $@; echo "report at $@"; touch -m -t 199001010000 $@; exit 1)

.PHONY: test

# ---------------------------------------------------------------------------------
# zip

zip: all
	bash misc/makezip2.sh -reveal-in-finder \
		"build/release/Inter2-$(VERSION)-$(shell git rev-parse --short=10 HEAD).zip"

zip_beta: \
		$(FONTDIR)/var/InterV.var.ttf \
		$(FONTDIR)/var/InterV.var.woff2 \
		$(FONTDIR)/var/InterV-Italic.var.ttf \
		$(FONTDIR)/var/InterV-Italic.var.woff2
	mkdir -p build/release
	zip -j -q -X "build/release/Inter_beta-$(VERSION)-$(shell date '+%Y%m%d_%H%M')-$(shell git rev-parse --short=10 HEAD).zip" $^

.PHONY: zip zip_beta

# ---------------------------------------------------------------------------------
# distribution
# - preflight checks for existing version archive and dirty git state.
# - step1 rebuilds from scratch, since font version & ID is based on git hash.
# - step2 runs tests, then makes a zip archive and updates the website (docs/ dir.)

DIST_ZIP = build/release/Inter2-${VERSION}.zip

dist: dist_preflight
	@# rebuild since font version & ID is based on git hash
	$(MAKE) -f $(MAKEFILE) -j$(nproc) dist_step1
	$(MAKE) -f $(MAKEFILE) -j$(nproc) dist_step2
	$(MAKE) -f $(MAKEFILE) dist_postflight

dist_preflight:
	@echo "——————————————————————————————————————————————————————————————————"
	@echo "Creating distribution for version ${VERSION}"
	@echo "——————————————————————————————————————————————————————————————————"
	@# check for existing version archive
	@if [ -f "${DIST_ZIP}" ]; then \
		echo "${DIST_ZIP} already exists. Bump version or rm zip file to continue." >&2; \
		exit 1; \
	fi
	@# check for uncommitted changes
	@git status --short | grep -qv '??' && (\
		echo "Warning: uncommitted changes:" >&2; git status --short | grep -v '??' ;\
		[ -t 1 ] || exit 1 ; \
		printf "Press ENTER to continue or ^C to cancel " ; read X) || true
	@#

dist_step1: clean
	$(MAKE) -f $(MAKEFILE) -j$(nproc) all

dist_step2: test
	$(MAKE) -f $(MAKEFILE) -j$(nproc) dist_zip dist_docs

dist_zip: | venv
	. $(VENV) ; python misc/tools/patch-version.py misc/dist/inter.css
	bash misc/makezip2.sh -reveal-in-finder "$(DIST_ZIP)"

dist_docs:
	$(MAKE) -C docs -j$(nproc) dist

dist_postflight:
	@echo "——————————————————————————————————————————————————————————————————"
	@echo ""
	@echo "Next steps:"
	@echo ""
	@echo "1) Commit & push changes"
	@echo ""
	@echo "2) Create new release with ${DIST_ZIP} at"
	@echo "   https://github.com/rsms/inter/releases/new?tag=v${VERSION}"
	@echo ""
	@echo "3) Bump version in version.txt (to the next future version)"
	@echo "   and commit & push changes"
	@echo ""
	@echo "——————————————————————————————————————————————————————————————————"

.PHONY: dist dist_preflight dist_step1 dist_step2 dist_zip dist_docs dist_postflight


# ---------------------------------------------------------------------------------
# install

INSTALLDIR := $(HOME)/Library/Fonts/Inter2

install: install_var \
  $(INSTALLDIR)/Inter2-Black.otf \
  $(INSTALLDIR)/Inter2-BlackItalic.otf \
  $(INSTALLDIR)/Inter2-Regular.otf \
  $(INSTALLDIR)/Inter2-Italic.otf \
  $(INSTALLDIR)/Inter2-Thin.otf \
  $(INSTALLDIR)/Inter2-ThinItalic.otf \
  $(INSTALLDIR)/Inter2-Light.otf \
  $(INSTALLDIR)/Inter2-LightItalic.otf \
  $(INSTALLDIR)/Inter2-ExtraLight.otf \
  $(INSTALLDIR)/Inter2-ExtraLightItalic.otf \
  $(INSTALLDIR)/Inter2-Medium.otf \
  $(INSTALLDIR)/Inter2-MediumItalic.otf \
  $(INSTALLDIR)/Inter2-SemiBold.otf \
  $(INSTALLDIR)/Inter2-SemiBoldItalic.otf \
  $(INSTALLDIR)/Inter2-Bold.otf \
  $(INSTALLDIR)/Inter2-BoldItalic.otf \
  $(INSTALLDIR)/Inter2-ExtraBold.otf \
  $(INSTALLDIR)/Inter2-ExtraBoldItalic.otf \
  $(INSTALLDIR)/Inter2-DisplayBlack.otf \
  $(INSTALLDIR)/Inter2-DisplayBlackItalic.otf \
  $(INSTALLDIR)/Inter2-Display.otf \
  $(INSTALLDIR)/Inter2-DisplayItalic.otf \
  $(INSTALLDIR)/Inter2-DisplayThin.otf \
  $(INSTALLDIR)/Inter2-DisplayThinItalic.otf \
  $(INSTALLDIR)/Inter2-DisplayLight.otf \
  $(INSTALLDIR)/Inter2-DisplayLightItalic.otf \
  $(INSTALLDIR)/Inter2-DisplayExtraLight.otf \
  $(INSTALLDIR)/Inter2-DisplayExtraLightItalic.otf \
  $(INSTALLDIR)/Inter2-DisplayMedium.otf \
  $(INSTALLDIR)/Inter2-DisplayMediumItalic.otf \
  $(INSTALLDIR)/Inter2-DisplaySemiBold.otf \
  $(INSTALLDIR)/Inter2-DisplaySemiBoldItalic.otf \
  $(INSTALLDIR)/Inter2-DisplayBold.otf \
  $(INSTALLDIR)/Inter2-DisplayBoldItalic.otf \
  $(INSTALLDIR)/Inter2-DisplayExtraBold.otf \
  $(INSTALLDIR)/Inter2-DisplayExtraBoldItalic.otf

install_var: \
	$(INSTALLDIR)/InterV.var.ttf \
	$(INSTALLDIR)/InterV-Italic.var.ttf

$(INSTALLDIR)/%.otf: $(FONTDIR)/static/%.otf | $(INSTALLDIR)
	cp -a $^ $@

$(INSTALLDIR)/%.var.ttf: $(FONTDIR)/var/%.var.ttf | $(INSTALLDIR)
	cp -a $^ $@

$(INSTALLDIR):
	mkdir -p $@

.PHONY: install install_var

# ---------------------------------------------------------------------------------
# misc

clean:
	rm -rf build/tmp build/fonts build/ufo build/googlefonts

docs:
	$(MAKE) -C docs serve

# update_ucd downloads the latest Unicode data (Nothing depends on this target)
ucd_version := 12.1.0
update_ucd:
	@echo "# Unicode $(ucd_version)" > misc/UnicodeData.txt
	curl '-#' "https://www.unicode.org/Public/$(ucd_version)/ucd/UnicodeData.txt" \
	>> misc/UnicodeData.txt

.PHONY: clean docs update_ucd

# ---------------------------------------------------------------------------------
# list make targets
#
# We copy the Makefile (first in MAKEFILE_LIST) and disable the include to only list
# primary targets, avoiding the generated targets.
list:
	@mkdir -p build/etc \
	&& cat $(MAKEFILE) \
	 | sed 's/include /#include /g' > build/etc/Makefile-list \
	&& $(MAKE) -pRrq -f build/etc/Makefile-list : 2>/dev/null \
	 | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' \
	 | sort \
	 | egrep -v -e '^_|/' \
	 | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

.PHONY: list

# ---------------------------------------------------------------------------------
# initialize toolchain

venv: build/venv/config.stamp

build/venv/config.stamp: requirements.txt
	@mkdir -p build
	test -d build/venv || python3 -m venv build/venv
	. $(VENV) ; pip install -Ur requirements.txt
	touch $@

reset: clean
	rm -rf build/venv

.PHONY: venv reset
