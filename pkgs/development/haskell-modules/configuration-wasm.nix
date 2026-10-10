{ pkgs, haskellLib }:

# Overrides for Haskell packages built for GHC's wasm backend (host platform
# wasm32-wasi, e.g. pkgsCross.wasm32-wasip1.haskellPackages). Typical entries:
# dependencies cabal2nix misses because they are conditional on arch(wasm32) or
# os(wasi), and packages or test suites that can't work under WASI, which has
# no processes, signals or threads.

self: super: { }
