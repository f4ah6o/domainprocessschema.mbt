set shell := ["bash", "-cu"]

default: check

fmt:
  moon fmt

check:
  moon check

test:
  moon test

build:
  moon build

wasm-demo-build:
  moon build wasm/demo --target wasm-gc --release

wasm-demo-test:
  moon test wasm/demo

test-js:
  pnpm test

demo-build:
  pnpm run build:demo

info:
  moon info

run *args:
  moon run cmd/main -- {{args}}
