# CLAUDE.md

Only what a capable agent would get wrong from this repo alone. Layout, dev
shells, build/test commands and dependency lists are discoverable and
deliberately absent (rainlanguage/rainix#298).

## What this repo is

The **deploy half** of `rainlang`: the concrete `RainlangParser`,
`RainlangStore`, `RainlangInterpreter`, `RainlangExpressionDeployer` and
`Rainlang`, their generated tables and deploy records, the deploy scripts +
tests, and the Rust crates that bind the deployed contracts. The parser, eval
loop, ops, integrity checks and the `BaseRainlang*` contracts the concretes
extend are NOT here — they arrive as the `rainlang` Soldeer package.

## Conventions an agent would get wrong

- Optimizer **1,000,000 runs**, NOT the 100,000 sibling deploy repos use.
  Deterministic (Zoltu) deploy: every address is a pure function of the creation
  bytecode, so this, solc `=0.8.25`, `evm_version = "cancun"`, no CBOR metadata,
  and the pinned `rainlang` sources all move the pins if changed.
- Pragma: concretes, scripts and tests pin `=0.8.25`; shipped libs and generated
  files float `^0.8.25`.
- `/test` is NOT in `.soldeerignore`: word and extern repos import
  `test/abstract/OpTest.sol` and `RainlangExpressionDeployerDeploymentTest.sol`
  through the published package, and both extend the `rainlang` package's own
  `test/abstract/` versions, so the package ships its tests too.
- `recursive_deps` is off: every package an import resolves through is declared
  in `foundry.toml`, including ones reached only via `rainlang`.
- NatSpec: if a doc block has any explicit tag, every entry must be tagged.

## Generated code

`script/Build.sol` writes ALL of it. Never hand-edit:

- `src/generated/<Name>Pointers.sol` — parse meta, function pointer tables, meta
  hashes. Committed because contract and pointers file depend on each other
  circularly.
- `src/generated/candidate/<Name>.sol` — each deployed contract's rolling deploy
  snapshot: hash, Zoltu address, creation/runtime code, dependencies.
  `src/lib/deploy/LibInterpreterDeploy.sol` is hand-written over these because
  its constant names and `etchRainlang` are a published consumer API.
- `src/generated/<x_y_z>/` — FROZEN release records. Append-only: never
  regenerate, move or delete a tag dir.
- `src/lib/Lib*Released.sol` and `src/lib/LibReleasedSuites.sol`.

After any change affecting bytecode, including a `rainlang` package bump:

1. `nix develop -c rainlang-prelude`
2. `nix develop -c forge script --silent ./script/Build.sol`
3. `nix develop -c forge fmt`
4. Repeat until `src/generated/` stops changing — deploy constants cascade
   parser → expression deployer → Rainlang; interpreter also cascades to
   Rainlang.

## Release / deploy shape

`src/abstract/RainlangDeploySuites.sol` is the ONE declaration of what this repo
deploys. `script/Deploy.sol`, `script/Build.sol` and the deploy tests all read
it.

`[external.package].version` in `foundry.toml` is the LAST Soldeer publish, not
a next-version slot: a normal PR never moves it. Releasing is deploy (Manual sol
artifacts, in suite order: parser, store, interpreter, expression-deployer,
rainlang) → verify (`RainlangDeployChainTest`) → a PR carrying `cutRelease()`'s
frozen dir and the version bump → merge → push `sol-v<x.y.z>`.

The Rust crates are NOT released by the tag — see `crates-release.yaml`. They
are bindings whose version tracks code changes and publish on merge.
