game_obj := \
home.o \
main.o \
wram.o

RGBDS ?=
RGBASM  ?= $(RGBDS)rgbasm
RGBFIX  ?= $(RGBDS)rgbfix
RGBGFX  ?= $(RGBDS)rgbgfx
RGBLINK ?= $(RGBDS)rgblink

.PHONY: all clean tidy

all: wordle
wordle: wordle.gbc

clean: tidy
	find gfx \( -name "*.[12]bpp" \) -delete

tidy:
	rm -f wordle.gbc $(game_obj) wordle.map wordle.sym
	$(MAKE) clean -C tools/

tools:
	$(MAKE) -C tools/

RGBASMFLAGS = -L -Weverything

define DEP
$1: $2 $$(shell tools/scan_includes $2)
	$$(RGBASM) $$(RGBASMFLAGS) -o $$@ $$<
endef

ifeq (,$(filter clean tidy tools,$(MAKECMDGOALS)))

$(info $(shell $(MAKE) -C tools))

$(foreach obj, $(game_obj), $(eval $(call DEP,$(obj),$(obj:.o=.asm))))

endif

fix_opt = -scjv -t WORDLE -i WRDL -n 0 -k 00 -l 0x33 -m 0x19 -r 0 -p 0

wordle.gbc: $(game_obj) layout.link
	$(RGBLINK) -n wordle.sym -m wordle.map -l layout.link -o $@ $(filter %.o,$^)
	$(RGBFIX) $(fix_opt) $@

%.2bpp: %.png
	$(RGBGFX) $(rgbgfx) -o $@ $<

%.1bpp: %.png
	$(RGBGFX) $(rgbgfx) -d1 -o $@ $<

%.gbcpal: %.png
	$(RGBGFX) -p $@ $<
