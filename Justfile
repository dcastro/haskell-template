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

format:
    ormolu --mode inplace $(git ls-files -- '*.hs')

checks:
    xreferee
    just test
    just format
    cabal clean && cabal build all --enable-tests --enable-benchmarks --ghc-options "-Werror"

haddock:
    ./scripts/check_haddock_warnings.sh lib:template

doctest:
    ./scripts/check_doctest.sh
    stack build doctest
    stack exec doctest -- $(find src \( -name '*.lhs' -o -name '*.hs' \) -print) \
        -XBlockArguments -XTypeFamilies -XQualifiedDo -XLambdaCase -XDataKinds
