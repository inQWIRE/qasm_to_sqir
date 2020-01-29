# OpenQASM to SQIR Translation

Work in progress

## Requirements
Current version of OCaml and the following dependencies:
```
$ opam install menhir utop openQASM
```

## Steps
Assuming a directory structures as follows:
```
inQWIRE
├── SQIR
└── qasm_to_sqir
```
- Install [dependencies](https://github.com/inQWIRE/SQIR#compilation) and run `make` in the SQIR directory.
- Run `./extractSQIRGates.sh` in `qasm_to_sqir` directory.
- `dune utop .`
- In the `utop` REPL, play with `Qasm_to_sqir.parse "<file>.qasm";;` etc.
