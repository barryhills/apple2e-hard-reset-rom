# Hard RESET ROM for Apple //e and Platinum

A patched Apple IIe ROM in which every reset is a hard reset. Power-on, Ctrl-Reset, Ctrl-Open-Apple-Reset and any /RESET from a card all land on the same screen:

```
SLOT (1-7)?    Apple //e
```

Press a slot number and that slot boots. There is no warm restart through the `$3F2` reset vector, so a program cannot trap Reset or keep the machine from coming back to the prompt.

It is a static ROM image: no accelerator conflicts (tested with a ZIP CHIP), no plugins, no extra hardware.

## Keys

| Key | Action |
| --- | --- |
| `1`-`7` | echo, beep, clear screen, boot the slot (`JMP $Cn00`) |
| `0` | echo, beep, clear screen, Applesoft cold start (`JMP $E000`) |
| anything else | beep, ignore, keep waiting |

Ctrl-Solid-Apple-Reset still runs the built-in self test, and Ctrl-Open-Apple-Reset still scrambles memory before the prompt, as on a stock machine.

## What changes from the stock ROM

Only the RESET/PWRUP block, `$FA62-$FAD4` (115 bytes), is replaced. Every other byte of the ROM is Apple's. The reset vector at `$FFFC` still points to `$FA62`, and `$FAA6` (`CALL -1370`) is still a valid cold-start entry.

On reset the patch:

1. switches the language card back to ROM,
2. runs the same initialisation as the stock RESET (`SETNORM`, `INIT`, `SETVID`, `SETKBD`, annunciators, the IIe housekeeping call at `$FBB4`, `$CFFF` to release slot expansion ROMs),
3. discards any key typed before reset,
4. clears the screen with the stock "Apple //e" banner and prints the prompt,
5. waits for a key and boots the slot, setting `$00/$01` and `MSLOT` (`$07F8`) as the stock autostart scan does.

Removed: the `$3F2`/`$3F4` warm-restart test, the autostart slot scan and the fall-through to BASIC when nothing boots (use `0`). Memory is not cleared.

## Images

Prebuilt images are in `rom/`. Or build your own from a stock ROM dump (see Building); the result is byte-identical.

| File | Machine | Replaces | Socket | Size | SHA1 |
| --- | --- | --- | --- | --- | --- |
| `rom/ef_hardreset.bin` | Enhanced IIe | 342-0303-A (EF) | EF | 8K, 2764 | `8d0d46ead8658ec37eb126d75d435b724fd81bcc` |
| `rom/cf_hardreset.bin` | IIe Platinum | 342-0349-B | single ROM | 16K, 27128 | `e6f097b249d051207c5298462fc6fca952d830c8` |

Stock ROM SHA1s: 342-0303-A `afb09bb96038232dc757d40c0605623cae38088e`, 342-0349-B `b8ea90abe135a0031065e01697c4a3a20d51198b`. The Platinum ROM is byte-identical to 342-0304-A followed by 342-0303-A, so the same patch goes at file offset `$1A62` in the 8K image and `$3A62` in the 16K one.

The unenhanced IIe ROMs are different code and are not supported.

Apart from the 115 patched bytes, the images in `rom/` are Apple's ROM code.

## Building

Needs cc65 (`ca65`, `ld65`) for the patch and python3 for the image.

```
make                                      # assemble patch/reset_patch.bin and listing/reset_patch.lst
make roms EF=342-0303-A.bin               # build/ef_hardreset.bin
make roms CF=342-0349-B.bin               # build/cf_hardreset.bin
```

or without make:

```
python3 tools/apply_patch.py 342-0303-A.bin ef_hardreset.bin
```

`apply_patch.py` refuses any input that is not one of the two stock ROMs, and checks the output SHA1 when the shipped patch is used.

## Files

| Path | Contents |
| --- | --- |
| `src/reset_patch.s` | source, ca65 syntax, 65C02 |
| `src/reset_patch.cfg` | ld65 config: one block at `$FA62`, `$73` bytes |
| `listing/reset_patch.lst` | assembler listing with addresses and bytes |
| `patch/reset_patch.bin` | the assembled 115 bytes for `$FA62-$FAD4` |
| `tools/apply_patch.py` | applies the patch to a stock ROM image |
| `rom/ef_hardreset.bin` | prebuilt 8K image, enhanced IIe EF socket |
| `rom/cf_hardreset.bin` | prebuilt 16K image, IIe Platinum |

### Patch bytes

For entering by hand or patching with a hex editor, at `$FA62-$FAD4`:

```
FA62: 2C 82 C0 D8 20 84 FE 20 2F FB 20 93 FE 20 89 FE
FA72: AD 58 C0 AD 5A C0 A0 09 20 B4 FB AD FF CF 2C 10
FA82: C0 20 60 FB B9 91 FA F0 1D 20 ED FD C8 80 F5 D3
FA92: CC CF D4 A0 A8 B1 AD B7 A9 BF A0 00 20 3A FF 80
FAA2: 05 4C 00 E0 80 BA AD 00 C0 10 FB 8D 10 C0 C9 B0
FAB2: 90 EA C9 B8 B0 E6 48 20 ED FD 20 3A FF 20 58 FC
FAC2: 68 29 0F F0 DC 09 C0 85 01 8D F8 07 64 00 6C 00
FAD2: 00 EA EA
```

## Chips

| Part | Notes |
| --- | --- |
| 2764 / 27C64 | EF socket, direct replacement |
| AT28C64B EEPROM | EF socket; pin 27 is /WE and must be held high by the socket, as for a 2764's /PGM |
| 27C128 | Platinum |
| [One ROM](https://github.com/piersfinlayson/one-rom) Fire 28 | plain image, no plugins: `type=2764` for the EF, `type=27128` for the Platinum. Build for the board actually fitted (`fire-28-a` for rev A-A4, `fire-28-c` for rev C) |

One ROM example, with the stock ROM in a second slot as a fallback on select jumper A:

```
onerom program --board fire-28-a \
  --slot "file=rom/ef_hardreset.bin,type=2764,label=Hard Reset" \
  --slot "file=342-0303-A.bin,type=2764,label=Stock EF" \
  --verify
```

## Tested

| Machine | Image | Carrier |
| --- | --- | --- |
| Enhanced IIe with ZIP CHIP and A2RESET card | EF | One ROM Fire 28 rev A3 |
| Enhanced IIe (stock) | EF | One ROM Fire 28 rev A3, AT28C64B |
| IIe Platinum | 16K | One ROM Fire 28 rev C (earlier revision of the patch, same block and entry points) |

## With an A2RESET card

The [A2RESET](https://github.com/rallepalaveev/A2RESET) card supplies its own hard-reset code when it captures the reset vector. When it misses (a release-timing race in the V1 card), the stock ROM warm-starts through `$3F2` and the reset looks soft. With this ROM in place, a missed capture still lands on a hard reset, so the card behaves reliably.

## License

MIT for the source, patch and tools. The ROM code in `rom/` outside `$FA62-$FAD4` is Apple's.
