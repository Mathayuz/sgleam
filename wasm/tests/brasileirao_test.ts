// Regression for the complete offline example on the browser's WASM engine.
// Run with a browser-sized stack to catch excessive sibling recursion:
// deno test --v8-flags=--stack-size=256 --allow-read wasm/tests/brasileirao_test.ts
// An optional argument after -- selects a different WASM binary.
import { makeWasi } from "./wasi.ts";

Deno.test("Brasileirao full snapshot, tests and initial view in WASM", async () => {
  const path = Deno.args[0] ??
    new URL(
      "../../target/wasm32-wasip1/release-small/sgleam.wasm",
      import.meta.url,
    );
  const bytes = await Deno.readFile(path);
  const module = await WebAssembly.compile(bytes);
  let ex: {
    memory: WebAssembly.Memory;
    string_allocate(size: number): number;
    repl_new(
      ptr: number,
      len: number,
      configPtr: number,
      configLen: number,
    ): number;
    repl_run(repl: number, ptr: number, len: number): number;
    repl_destroy(repl: number): void;
  };
  let output = "";
  const frames: string[] = [];
  const decoder = new TextDecoder();
  const read = (ptr: number, len: number) =>
    decoder.decode(new Uint8Array(ex.memory.buffer, ptr, len));
  const env: Record<string, (...args: number[]) => number | void> = {};
  for (const entry of WebAssembly.Module.imports(module)) {
    if (entry.module === "env") env[entry.name] = () => 0;
  }
  env.draw_view = (ptr, len) => {
    frames.push(read(ptr, len));
  };
  env.wait_event = () => 2;
  env.get_key_event = () => 3;
  const wasi = makeWasi({
    getBuffer: () => ex.memory.buffer,
    write: (_, text) => {
      output += text;
    },
    isTty: false,
  });
  const instance = await WebAssembly.instantiate(module, {
    env,
    wasi_snapshot_preview1: wasi,
  });
  ex = instance.exports as unknown as typeof ex;
  function encode(s: string): [number, number] {
    const data = new TextEncoder().encode(s);
    const ptr = ex.string_allocate(data.length);
    new Uint8Array(ex.memory.buffer, ptr, data.length).set(data);
    return [ptr, data.length];
  }
  const code = await Deno.readTextFile(
    new URL("../../examples/app_brasileirao.gleam", import.meta.url),
  );
  const repl = ex.repl_new(...encode(code), ...encode(""));
  console.log(output);
  if (!repl || !output.includes("0 failures and 0 errors")) {
    throw new Error("Example tests failed: " + output);
  }
  const status = ex.repl_run(repl, ...encode("main()"));
  if (
    status !== 0 || !frames.some((s) => s.includes("São Paulo FC") && s.includes("<option"))
  ) {
    throw new Error("Application did not render loaded data: " + output);
  }
  ex.repl_destroy(repl);
});
