import GUI from 'lil-gui';
import roms from 'virtual:roms';

const wasm = await (await fetch('/zhip8.wasm')).arrayBuffer();
const { instance } = await WebAssembly.instantiate(wasm);
const { memory, chip_init, chip_load, chip_step, chip_key, chip_fb_ptr } = instance.exports;

const W = 64;
const H = 32;
const SCALE = 12;

document.querySelector('#app').innerHTML = `<canvas id="screen" width="${W * SCALE}" height="${H * SCALE}"></canvas>`;
const canvas = document.querySelector('#screen');
const ctx = canvas.getContext('2d');
ctx.imageSmoothingEnabled = false;

const mem = new Uint8Array(memory.buffer);
const romPtr = 0x200;
let fb = new Uint8Array(memory.buffer, Number(chip_fb_ptr()), W * H);

async function loadRom(name) {
  const rom = new Uint8Array(await (await fetch(`/_roms/${name}`)).arrayBuffer());
  chip_init();
  mem.set(rom, romPtr);
  chip_load(romPtr, rom.length);
  fb = new Uint8Array(memory.buffer, Number(chip_fb_ptr()), W * H);
}

const state = { rom: roms[0] };
new GUI().add(state, 'rom', roms).name('Program').onChange(loadRom);
await loadRom(state.rom);

const KEYMAP = {
  '1': 0x1, '2': 0x2, '3': 0x3, '4': 0xC,
  q: 0x4, w: 0x5, e: 0x6, r: 0xD,
  a: 0x7, s: 0x8, d: 0x9, f: 0xE,
  z: 0xA, x: 0x0, c: 0xB, v: 0xF,
};

addEventListener('keydown', (e) => {
  const key = KEYMAP[e.key.toLowerCase()];
  if (key === undefined) return;
  e.preventDefault();
  if (!e.repeat) chip_key(key, true);
});

addEventListener('keyup', (e) => {
  const key = KEYMAP[e.key.toLowerCase()];
  if (key === undefined) return;
  e.preventDefault();
  chip_key(key, false);
});

function render() {
  for (let i = 0; i < 10; i += 1) chip_step();
  ctx.fillStyle = '#111';
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = '#6cf06c';
  for (let y = 0; y < H; y += 1) {
    for (let x = 0; x < W; x += 1) {
      if (fb[y * W + x]) ctx.fillRect(x * SCALE, y * SCALE, SCALE, SCALE);
    }
  }
  requestAnimationFrame(render);
}

render();
