# m6502

Simple SBC based on 65c02s

Discussion: <http://forum.6502.org/viewtopic.php?f=12&t=7501>

- [Kicad files](./kicad)
- [DipTrace PCBs](./diptrace)
- [Circuits](./circuits) (created with [Digital](https://github.com/hneemann/Digital))
- [ROM sources](./rom)
- [LCD decoder](./lcd) using GAL16V8 (includes `galasm` sources)

# Memory map

```
+-------+-----+------------------------+
| RANGE | TYP | Notes                  |
+-------+-----+------------------------+
| $0000 | RAM | NAND(A14, A15)         |
| $BFFF | 48k |                        |
+-------+-----+------------------------+
| $C000 | I/O | !RAM && !A12 && !A13   |
|  ...  | 4k  | $C000-$C0FF - LCD      |
|  ...  |     | $C100-$C1FF - 6522 VIA |
|  ...  |     | $C200-$C2FF - EEPROM?  |
| $CFFF |     | $C300-$C3FF - SID?     |
+-------+-----+------------------------+
| $D000 | n/a | Reserved for future    |
| $DFFF | 4k  |                        |
+-------+-----+------------------------+
| $E000 | ROM | !RAM && A13            |
| $FFFF | 8k  |                        |
+-------+-----+------------------------+
```

# Links
- Address Selector: https://circuitverse.org/simulator/embed/6502-address-selector
- Read-Write Selector: https://circuitverse.org/simulator/embed/6502-read-write-selector
