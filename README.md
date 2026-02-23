zig chip8 emulator w/ [libvaxis](https://github.com/rockorager/libvaxis) and roms from [John Earnest](https://github.com/repos/JohnEarnest/chip8Archive)



spec
- 16 8-bit registers `V0` to `VF` (`0x00` - `0xFF`)
- 4096 bytes of memory (`0x000` to `0xFFF`)
    - `0x000-0x1FF` for interpreter
    - `0x050-0x0A0` storage space for 16 built-in characters 
    - `0x200-0xFFF` instructions from ROM 
- (DT) - 60Hz clock that goes to 0
- (ST) - Activate sound whenever nonzero 

todo
- [x] super chip8
- some networking
- [x] wasm port

usage
```shell
just tui _roms/snake.ch8
```

or for web usage 
```shell
cd web
bun dev
```