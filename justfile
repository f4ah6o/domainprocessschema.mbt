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

info:
  moon info

run *args:
  moon run cmd/main -- {{args}}
