# Terminology

This document describes terminology used in Satyrographos.

## Paths

### SATySFi Root Directory

A directory which has SATySFi-related files, i.e., `dist` or `local` directories. E.g., `~/.satysfi`, `/usr/local/satysfi`, `/usr/satysfi`.

Official terms:

- [(SATySFi) root dir](https://github.com/gfngfn/SATySFi/blob/c841df2d68738f1d5cd86d59e14e7bbd4137d8d8/src/config.ml#L14)
- [configuration search path](https://github.com/gfngfn/SATySFi/blob/c841df2d68738f1d5cd86d59e14e7bbd4137d8d8/src/frontend/main.ml#L1017)

### SATySFi Library Path

A path relative to SATySFi Root Directory.

Official terms:

- [lib path](https://github.com/gfngfn/SATySFi/blob/master/src/config.ml#L27)

### SATySFi Package Root Directory

A directory to where required package paths are relative.

This is either `dist/packages` or `local/packages` under a SATySFi Root Directory since SATySFi 0.0.4;
meanwhile it was only `dist/packages` in SATySFi 0.0.3 and earlier.
