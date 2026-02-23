import wasmUrl from "../zig-out/bin/zhip8.wasm";

type Zhip8Exports = {
  chip_init(): void;
  chip_step(): void;
  chip_load(ptr: number, len: number): void;
  chip_key(key: number, pressed: number): void;
  chip_fb_ptr(): number;
  memory: WebAssembly.Memory;
};

console.log("Loading WebAssembly module from:", wasmUrl);
console.log("Loading WebAssembly module from:", wasmUrl);
const { instance } = await WebAssembly.instantiateStreaming(fetch(wasmUrl), {});
const wasm = instance.exports as unknown as Zhip8Exports;
wasm.chip_init();
