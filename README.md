# m6502

![65c02s SBC](./img/v09_3d.jpg)

Simple SBC based on W65C02S

Discussion: <http://forum.6502.org/viewtopic.php?f=12&t=7501>

Pull with `git pull --recurse-submodules`.

# Components

- CPU: W65C02S(6TPG)
- RAM: AS6C1008
- ROM: W27C512
- I/O: VIA W65C22N(6TPG)
- Glue logic: 74HC00, 74HC138
- 1 MHz oscillator (DIP-14)
- Traco Power TSC 1-2450 (drop-in replacement for LD7805)

I/O:
- 2004 LCD 16-pin header
- 2 ports & control lines from 6522 VIA

To be added in future versions:
- 8580R5 SID
- 6551 ACIA

![65c02s SBC PCB](./img/v09_routed.png?1)

![65c02s SBC PCB](./img/v09.png)

# Resources

- [Kicad files](./kicad) - <https://www.kicad.org/>
- [DipTrace PCBs](./diptrace) - <https://diptrace.com/>
- [Circuits](./circuits) (created with [Digital](https://github.com/hneemann/Digital))
- [ROM sources](./rom) (requires [cc65](https://cc65.github.io/) compiler)
- [GAL stuff](./gal) (hexadecimal 7-segment decoder, address decoder, etc using GAL16V8/GAL20V8, includes `galasm` as submodule)

# Memory map

```
+-------+-----+------------------------+
| RANGE | TYP | Notes                  |
+-------+-----+------------------------+
| $0000 | RAM | NAND(A14, A15)         |
| $BFFF | 48k |                        |
+-------+-----+------------------------+
| $C000 | n/a | Reserved for future    |
| $CFFF | 4k  |                        |
+-------+-----+------------------------+
| $D000 | I/O | !RAM && !ROM && A12    |
|  ...  | 4k  | $D000-$D0FF - LCD      |
|  ...  |     | $D100-$D1FF - 6522 VIA |
|  ...  |     | $D200-$D2FF - EEPROM?  |
|  ...  |     | $D300-$D3FF - EEPROM?  |
| $DFFF |     | $D400-$D4FF - SID?     |
+-------+-----+------------------------+
| $E000 | ROM | !RAM && A13            |
| $FFFF | 8k  |                        |
+-------+-----+------------------------+
```

# Links
- 6502 Primer: http://wilsonminesco.com/6502primer/
- Address Selector: https://circuitverse.org/simulator/embed/6502-address-selector
- Read-Write Selector: https://circuitverse.org/simulator/embed/6502-read-write-selector
- SID (HVSC) format: https://gist.github.com/cbmeeks/2b107f0a8d36fc461ebb056e94b2f4d6
