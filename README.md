# Deck65

Homebrew 6502-based single-board computer with WiFi, built-in mechanical keyboard, uSD card adapter, I2C/SPI, EEPROM, & RTC.

![Deck65 SBC](./img/case_9_live.jpg)
![Deck65 SBC](./img/v2_0_assembled2.jpg)
![Deck65 SBC](./img/v2_0_pcb3.jpg)

- New discussion: <http://forum.6502.org/viewtopic.php?f=6&t=7682>
- Original thread (old SBC version): <http://forum.6502.org/viewtopic.php?f=12&t=7501>

Pull with `git pull --recurse-submodules`.

# Memory map

```
+--------------+-------+------------------+------+------------------------------------------+
| RANGE        | TYPE  | ADDR             | SIZE | Notes                                    |
+--------------+-------+------------------+------+------------------------------------------+
| $0000..$0FFF | RAM   | 0000------------ | 32 K | /EN = A15                                |
| $1000..$1FFF |       | 0001------------ |      | $0000..$1000 - zeropage & video buffer   |
| $2000..$2FFF |       | 0010------------ |      | $1000..$7FFF - programs from SD Card     |
| $3000..$3FFF |       | 0011------------ |      |                                          |
| $4000..$4FFF |       | 0100------------ |      |                                          |
| $5000..$5FFF |       | 0101------------ |      |                                          |
| $6000..$6FFF |       | 0110------------ |      |                                          |
| $7000..$7FFF |       | 0111------------ |      |                                          |
+--------------+-------+------------------+------+------------------------------------------+
| $8000..$8FFF | LOROM | 1000------------ | 16 K | /EN = NAND(A15, NAND(A14))               |
| $9000..$9FFF |       | 1001------------ |      | Contains OS ("MicroREPL")                |
| $A000..$AFFF |       | 1010------------ |      |                                          |
| $B000..$BFFF |       | 1011------------ |      |                                          |
+--------------+-------+------------------+------+------------------------------------------+
| $C000..$CFFF | N/C   | 1100------------ | 4 K  | Unused, may add extra '138 with /GA=/A13 |
+--------------+-------+------------------+------+------------------------------------------+
| $D000..$DFFF | I/O   | 1101------------ | 4 K  | G = A12, /GA = A13, /GB = NAND(A15, A14) |
|              |       | 1101-000-------- | 256B | $D000..$D0FF - RAM banking register      |
|              |       | 1101-001-------- | 256B | $D100..$D1FF - 6522 VIA                  |
|              |       | 1101-010-------- | 256B | $D200..$D2FF - 6551 ACIA                 |
|              |       | 1101-011-------- | 256B | $D300..$D3FF - T6963C LCD (240x64)       |
+--------------+-------+------------------+------+------------------------------------------+
| $E000..$EFFF | HIROM | 1110------------ | 8 K  | /EN = NAND(/NAND(A15, A14), A13)         |
| $F000..$FFFF |       | 1111------------ |      | Contains Kernel ("Kore")                 |
+--------------+-------+------------------+------+------------------------------------------+

LOROM (10xx) || HIROM (111x):
/EN = A15 && (/A14 || (A14 && A13))
/EN = NAND(A15, /A14 || /NAND(A14, A13))
/EN = NAND(A15, NAND(A14, NAND(A14, A13)))
```

# Features

- W65C02, 512 KB RAM (32KB visible to CPU, banked into 4 x 8 KB segments)
- 240x64 LCD display (T6963C)
- Built-in [mechanical PS/2 keyboard](./keyboard), powered by ATmega328P
- Internet! Works through ESP-01
- VIA W65C22<ins>N</ins>(6TPG-14)

  Provides:
  - SPI (used for Micro SD Card adapter)
  - I2C (used for RTC & EEPROM)
  - PS/2 host (used for built-in or external keyboard)
- ACIA W65C51<ins>N</ins>(6TPG-14)n

  Provides:
  - Communication with ESP-01
  - Communication with external devices through pin header
  > Note: I'm using NMOS-compatible versions of VIA & ACIA (<ins>N</ins> suffix) with open-drain /IRQ line.<br />
  > See http://archive.6502.org/datasheets/wdc_w65c22_sep_13_2010.pdf (page 25) for more details.
- Address decoder & underclocking - [ATF16V8B-15PU](./gal)
  > Main crystal is 16 MHz, and the CPU runs at either 8 MHz or 2 MHz.<br />
  > Reason for this is that T6963C LCD can only operate on up to 2.75 MHz.<br />
  > So when CPU needs to acccess the LCD, ATF16V8 divides clock speed by 4, bringing it down to 2 MHz.<br />
  > This is done by implementing a 2-bit counter using registered outputs.
- Memory banking: 74LS670
  > Entire RAM (first 32 KB) is divided into 4 x 8 KB segments.<br />
  > Each segment can use one of its own 16 banks.<br />
  > This allows to selectively bank parts of RAM in and out.<br />
  > Using a machine-tooled socket actually allows to connect JCO-8 or JCO-14 oscillators.
- Traco Power TSR 1-2450 (drop-in replacement for 7805)
  > It runs much cooler than L7805 since it's a switching regulator.<br />
  > I use them a lot, although they are not as cheap as 7805.

V2.0 schematic:
![65c02s SBC PCB](./img/v2_0_schematic.png)

# ROM

Kernel code currently provides the following features:
- Simple REPL shell to monitor memory & run programs
- 128x64 LCD (through VIA)
- PS/2 keyboard (through VIA)
- Micro SD Card in SPI mode (through VIA)
- I2C & SPI support
- Basic FAT16 support - listing root folder, loading/executing programs

# Resources

- [Kicad files](./kicad) - <https://www.kicad.org/>
- [DipTrace PCBs](./diptrace) - <https://diptrace.com/>
- [Circuits](./circuits) (created with [Digital](https://github.com/hneemann/Digital))
- [ROM sources](./rom) (written in 6502 Assembly, requires [cc65](https://cc65.github.io/) compiler)
- [SD Card programs](./sdcard) (written in 6502 C, requires [cc65](https://cc65.github.io/) compiler)
- [Keyboard firmware](./keyboard) (written in C)
- [GAL stuff](./gal) (hexadecimal 7-segment decoder, address decoder, etc using GAL16V8/GAL20V8, includes `galasm` as submodule)
- [Composite video test](./compvid) using ATtiny45 (requires [avra](https://github.com/Ro5bert/avra))

# So what can you do with it?

Playing snake, for example:

[![Snake on 65C02 SBC](./img/snake_yt.jpg)](https://www.youtube.com/watch?v=boeysL1Isg4)

# Credits & references
- [6502.org community](forum.6502.org/) - Limitless help & support
- https://www.masswerk.at/6502/6502_instruction_set.html
- https://github.com/4x1md/kicad_libraries - Mini-DIN-6 symbol & footprint
- http://39k.ca/reading-files-from-fat16/
- https://laughtonelectronics.com/Arcana/KimKlone/Kimklone_opcode_mapping.html - cool illegal NOPs
- https://octopart.componentsearchengine.com/part.php?partID=570717&ref=octopart - Aries 28-526-10 footprint
- https://github.com/daprice/keyswitches.pretty - MX switches
- https://components101.com/sites/default/files/component_datasheet/Micro-SD-Card-Module-Datasheet.pdf - MicroSD card module datasheet & dimensions
- http://static.cactus.io/docs/sensors/temp-humidity/mcp9808/25095A.pdf - MCP9808 I2C temperature sensor
- https://ww1.microchip.com/downloads/aemDocuments/documents/MPD/ProductDocuments/DataSheets/24AA512-24LC512-24FC512-512K-Bit-I2C-Serial-EEPROM-20001754Q.pdf

# Links
- 6502 Primer: http://wilsonminesco.com/6502primer/
- Address Selector: https://circuitverse.org/simulator/embed/6502-address-selector
- Read-Write Selector: https://circuitverse.org/simulator/embed/6502-read-write-selector
- SID (HVSC) format: https://gist.github.com/cbmeeks/2b107f0a8d36fc461ebb056e94b2f4d6
