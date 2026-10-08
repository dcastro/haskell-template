# Just list all recipes by default
default:
    just --list

build:
    cabal build all --enable-tests --enable-benchmarks

freeze:
    rm cabal.project.freeze ; cabal freeze --enable-tests --enable-benchmarks

test:
    cabal test all

test-filter filter:
    watchexec --clear --restart \
      --exts hs,yaml,cabal \
      -- 'cabal test all --test-options="--filter \"{{ filter }}\""'

format:
    ormolu --mode inplace $(git ls-files -- '*.hs')

checks:
    just doctest
    just haddock
    just pandoc
    just format
    # check markdown links
    xrefcheck --ignore "release/**/*"
    # Check cross-references "ref:" in the repo
    xreferee --include-untracked
    # Build with `-Werror`
    cabal clean && cabal build all --enable-tests --enable-benchmarks --ghc-options "-Werror"
    # Run the tests
    just test
    # Build with the lowest supported version of each dependency.
    cabal clean && just min-deps

min-deps:
    cabal build lib:template \
        --project-file=cabal.project.min-deps \
        --prefer-oldest \
        --builddir=dist-min-deps \
        --ghc-options "-Werror" \
        --with-compiler=ghc-9.10.3

# Run doctest for all components, or only for the given cabal targets. E.g. `just doctest linear-effectful:lib:linear-effectful`
doctest *TARGETS:
    ./scripts/check_doctest.sh
    ./scripts/run_doctest.sh {{ TARGETS }}

haddock:
    ./scripts/check_haddock_warnings.sh lib:template

# Run haddock in "file watch" mode
haddock-fw:
    watchexec --restart --clear --exts hs -- just haddock

haddock-hackage *ARGS:
    cabal update
    cabal haddock lib:template --haddock-for-hackage {{ ARGS }}

pandoc:
    ./scripts/run_pandoc.sh

############################################################################
## Release
############################################################################

upload-candidate:
    just checks

    rm -rf dist-newstyle
    rm -rf release && mkdir release

    cabal sdist --builddir release
    cabal upload release/sdist/*.tar.gz

upload-candidate-docs *ARGS:
    just checks

    rm -rf release/docs
    mkdir -p release/docs
    cabal update
    cabal haddock lib:template --haddock-for-hackage --builddir release/docs
    cabal upload --documentation {{ ARGS }} release/docs/*-docs.tar.gz

upload-final-docs:
    just upload-candidate-docs --publish
