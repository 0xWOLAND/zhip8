import GUI from 'lil-gui';
import roms from 'virtual:roms';

const W = 64;
const H = 32;
const SCALE = 12;
const ROM_PTR = 0x200;
const BG = '#111';
const FG = '#6cf06c';

const app = document.querySelector('#app');
app.innerHTML = `<canvas id="screen" width="${W * SCALE}" height="${H * SCALE}"></canvas>`;
const canvas = document.querySelector('#screen');
const ctx = canvas.getContext('2d', { alpha: false });
if (!ctx) throw new Error('2D canvas context unavailable');
ctx.imageSmoothingEnabled = false;

const wasm = await (await fetch('/zhip8.wasm')).arrayBuffer();
const { instance } = await WebAssembly.instantiate(wasm);
const { memory, chip_init, chip_load, chip_step, chip_key, chip_fb_ptr } = instance.exports;

const mem = new Uint8Array(memory.buffer);
let fb = new Uint8Array(memory.buffer, Number(chip_fb_ptr()), W * H);
let isLoadingRom = false;
let loadToken = 0;

async function loadRom(name) {
  const token = ++loadToken;
  isLoadingRom = true;

  try {
    const rom = new Uint8Array(await (await fetch(`/_roms/${name}`)).arrayBuffer());
    if (token !== loadToken) return;

    chip_init();
    for (let key = 0; key < 16; key += 1) chip_key(key, false);

    mem.set(rom, ROM_PTR);
    chip_load(ROM_PTR, rom.length);
    fb = new Uint8Array(memory.buffer, Number(chip_fb_ptr()), W * H);
  } finally {
    if (token === loadToken) isLoadingRom = false;
  }
}

const state = { rom: roms[0], tickSpeed: 4 };
const gui = new GUI();
gui.add(state, 'rom', roms).name('Program').onChange((name) => {
  loadRom(name).catch((err) => console.error('ROM load failed:', err));
});
gui.add(state, 'tickSpeed', 1, 10, 1).name('Tick Speed');
await loadRom(state.rom);

const KEYMAP = Object.freeze({
  '1': 0x1, '2': 0x2, '3': 0x3, '4': 0xC,
  q: 0x4, w: 0x5, e: 0x6, r: 0xD,
  a: 0x7, s: 0x8, d: 0x9, f: 0xE,
  z: 0xA, x: 0x0, c: 0xB, v: 0xF,
});

function setKey(pressed, e) {
  const key = KEYMAP[e.key.toLowerCase()];
  if (key === undefined) return;
  e.preventDefault();
  if (pressed && e.repeat) return;
  chip_key(key, pressed);
}

addEventListener('keydown', (e) => setKey(true, e));
addEventListener('keyup', (e) => setKey(false, e));

function stepCpu() {
  for (let i = 0; i < state.tickSpeed; i += 1) chip_step();
}

function drawFrame() {
  ctx.fillStyle = BG;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = FG;
  for (let i = 0; i < W * H; i += 1) {
    if (!fb[i]) continue;
    const x = i % W;
    const y = (i / W) | 0;
    ctx.fillRect(x * SCALE, y * SCALE, SCALE, SCALE);
  }
}

function render() {
  if (!isLoadingRom) {
    stepCpu();
  }
  drawFrame();
  requestAnimationFrame(render);
}

render();
