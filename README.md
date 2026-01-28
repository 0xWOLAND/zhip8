spec
- 16 8-bit registers `V0` to `VF` (`0x00` - `0xFF`)
- 4096 bytes of memory (`0x000` to `0xFFF`)
    - `0x000-0x1FF` for interpreter
    - `0x050-0x0A0` storage space for 16 built-in characters 
    - `0x200-0xFFF` instructions from ROM 