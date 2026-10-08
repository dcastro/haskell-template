#!/usr/bin/env bash
set -euo pipefail

: <<'END'

Runs doctest for each component (libraries, test suites, etc.) of each package in the project.

We can't use `cabal doctest`, because it only runs doctest for libraries.
It ignores the other components without an error.

We can't use `cabal repl all --enable-multi-repl --with-repl=doctest` either,
because doctest does not support the `-unit` flag.

So we run `cabal repl --with-repl=doctest` once for each component.

Usage:
  run_doctest.sh             # Run doctest for all components.
  run_doctest.sh TARGET...   # Run doctest only for the given cabal targets,
                             # e.g. `linear-effectful:lib:linear-effectful`.

END

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Install doctest in `./bin`, built with the same GHC version as the project.
cabal install doctest \
  --ignore-project \
  --with-compiler=ghc-9.14.1 \
  --installdir=./bin \
  --install-method=copy \
  --overwrite-policy=always

if [[ $# -gt 0 ]]; then
  # Use the targets given as arguments, one per line.
  targets="$(printf '%s\n' "$@")"
else
  # Update `plan.json` so that it lists the test suites and benchmarks too.
  cabal build all --enable-tests --enable-benchmarks --dry-run > /dev/null

  # The cabal targets for all the components of the local packages, one per line.
  # E.g. `linear-effectful:lib:linear-effectful` or `linear-effectful:test:linear-effectful-test`.
  targets="$(jq -r '
    .["install-plan"][]
    | select(.style == "local")
    | if .["component-name"] == "lib"
      then "\(.["pkg-name"]):lib:\(.["pkg-name"])"
      else "\(.["pkg-name"]):\(.["component-name"])"
      end
    ' dist-newstyle/cache/plan.json)"
fi

while read -r target; do
  echo "Running doctest for ${target}"
  # Cabal runs the repl in the package's directory, so the path to doctest must be absolute.
  cabal repl "${target}" --with-repl="${repo_root}/bin/doctest" --repl-options=-w
done <<< "${targets}"
