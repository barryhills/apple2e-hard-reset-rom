# Makefile - hard-reset ROM patch for the enhanced Apple IIe / IIe Platinum
#
#   make                      assemble patch/reset_patch.bin and the listing
#   make roms EF=<342-0303-A image> CF=<342-0349-B image>
#                             build build/ef_hardreset.bin and/or
#                             build/cf_hardreset.bin from your own stock ROMs
#
# Needs cc65 (ca65, ld65) and python3.

AS = ca65
LD = ld65

all: patch/reset_patch.bin

build:
	mkdir -p build

build/reset_patch.o: src/reset_patch.s | build
	$(AS) --cpu 65C02 -l listing/reset_patch.lst $< -o $@

patch/reset_patch.bin: build/reset_patch.o src/reset_patch.cfg
	$(LD) -C src/reset_patch.cfg $< -o $@
	@echo "patch/reset_patch.bin: $$(wc -c < $@) bytes"

roms: patch/reset_patch.bin | build
	@[ -n "$(EF)$(CF)" ] || { echo "usage: make roms EF=<342-0303-A> CF=<342-0349-B>" >&2; exit 1; }
	@if [ -n "$(EF)" ]; then python3 tools/apply_patch.py "$(EF)" build/ef_hardreset.bin; fi
	@if [ -n "$(CF)" ]; then python3 tools/apply_patch.py "$(CF)" build/cf_hardreset.bin; fi

clean:
	rm -rf build

.PHONY: all roms clean
