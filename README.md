# rainlang.deploy

The **deployment** half of
[`rainlang`](https://github.com/rainlanguage/rainlang): the concrete
`RainlangParser`, `RainlangStore`, `RainlangInterpreter`,
`RainlangExpressionDeployer` and `Rainlang` contracts, the rolling
`src/generated/candidate/` snapshots of their deterministic Zoltu deploy records
(address, codehash, creation and runtime bytecode), the hand-written pin lib
`src/lib/deploy/LibInterpreterDeploy.sol` over those records, the generated
parse meta and function pointer tables the concretes bind, the deploy scripts +
tests, and the Rust crates that bind the deployed contracts.

The **library** half — the parser, eval loop, standard ops, integrity checks,
the `BaseRainlang*` contracts the concretes extend and the extern / sub-parser
bases — lives in `rainlang` and is imported here as the `rainlang` Soldeer
package. Consumers that build words or externs against the library depend on
`rainlang`; consumers that need the deployed addresses, codehashes or a test
harness over the live contracts (`OpTest`, `LibInterpreterDeploy`) depend on
`rainlang-deploy`.

## The deploy surface

- `src/concrete/*.sol` — the deployed contracts. Each extends its `rainlang`
  `BaseRainlang*` and binds the generated tables under `src/generated/` and the
  Zoltu addresses under `src/lib/deploy/LibInterpreterDeploy.sol`.
- `src/abstract/RainlangDeploySuites.sol` — everything this repo deploys,
  declared once: the five candidate suites that `script/Build.sol`,
  `script/Deploy.sol` and the deploy tests all bind to.
- `src/generated/candidate/*.sol` — the rolling deploy records, rewritten from
  what source compiles to by `script/Build.sol` and currency-checked by CI. A
  release cut freezes them into `src/generated/<tag>/`. NEVER edit by hand.
- `src/generated/*Pointers.sol` — the parse meta, function pointer tables and
  meta hashes each concrete compiles against. NEVER edit by hand.
- `src/lib/deploy/LibInterpreterDeploy.sol` — the stable import path over the
  candidate pins, plus `etchRainlang` for tests.
- `src/lib/LibReleasedSuites.sol` (+ the per-contract `Lib*Released.sol`) — the
  generated record of every released suite. NEVER edit by hand.
- `test/abstract/OpTest.sol`,
  `test/abstract/RainlangExpressionDeployerDeploymentTest.sol` — the `rainlang`
  package's test harness bound to the deployed contracts, for word and extern
  repos.
- `script/Deploy.sol` — deploys one suite via the Zoltu deterministic deployer.
- `crates/` — Rust bindings, dispair, parser, eval, cli and test fixtures over
  the deployed contracts' ABIs, copied from the forge artifacts by
  `script/CopyArtifacts.sol`.

## Conventions

- Concretes, scripts and tests pin `=0.8.25`; the shipped libs float `^0.8.25`.
  Optimizer on at **1,000,000 runs** (see `foundry.toml`) — this is what the
  live deployments used, and the pins move if it changes.
- Cancun, no CBOR metadata. Soldeer deps carry the version in the import path;
  `recursive_deps` is off, so every transitively reached package is declared.

## Releases

Releases are manual `sol-v*` tags, never merges.

The on-chain deploy comes first and is human-dispatched: the
`Manual sol artifacts` workflow runs `script/Deploy.sol` once per suite, in
order `parser`, `store`, `interpreter`, `expression-deployer`, `rainlang`,
because the later suites embed the earlier ones' addresses. Where an address
already holds its code (deterministic Zoltu), a deploy attests the existing code
rather than deploying fresh.

Then `RainlangDeployChainTest` verifies every suite is live on every supported
network, a PR carries `cutRelease()`'s frozen `src/generated/<tag>/` and the
`[external.package].version` bump, and pushing `sol-v<x.y.z>` on the merged
commit publishes the `rainlang-deploy` Soldeer package.

The Rust crates publish on merge to `main` via `crates-release.yaml`.
