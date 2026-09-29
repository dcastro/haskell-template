# Just list all recipes by default
default:
    just --list

build:
    cabal build all --enable-tests --enable-benchmarks --ghc-options "-Werror"

test:
    cabal test

test-filter filter:
    watchexec --clear --restart \
      --exts hs,yaml,cabal \
      -- 'cabal test --test-options="--filter \"{{ filter }}\""'

install:
    cabal install --overwrite-policy=always

format:
    ormolu --mode inplace $(git ls-files -- '*.hs' ':!:src/ExceptionUtil.hs')

checks:
    xreferee
    just test
    just format
    cabal clean && cabal build all --enable-tests --enable-benchmarks --ghc-options "-Werror"
