# Lint subcommand

Lint subcommand detects problems in Satyristes, OPAM files, and SATySFi files.

## Command line interface

```sh
satyrographos [--verbose] [--script <satyristes-path>] [-W <warning-expr>]
```

- `--verbose` makes the output verbose
- `--script` points to `Satyristes` file.  Its default value is `./Satyristes`.
- `-W` can enable/disable warnigs.

## Problem class

Each problem is classified one problem class.  For example, the following problems belong to `lib/version` problem class.

- A Satyrographos library has an empty version id.
- A Satyrographos library has an invalid version id.

Each OPAM Lint error/warning is considered as problem class `opam-file/lint/<opam-warning-no>`. For example, an empty `synopsis` field causes `opam-file/lint/47`.

### `-W` option

`-W` option is added to disable warnings/errors being reported by `lint` subcommand.

For now, `-W` option can disable not only warning but also errors. This behavior should be revised when lint subcommand is stable enough since errors should not be turned off.

`-W` option takes a warning expression.  The grammar is following.

```bnf
main ::=
  | exprs

exprs ::=
  | expr ( "," expr )*
    -- List of exprs
  | ( atom "/" )* "{" exprs "}"
    -- Common prefix for the exprs

expr ::=
  | ( "+" | "-" ) glob
    -- Enable or disable warnings matching the glob

glob ::=
  | "*"
  | atom
  | atom "/" glob
  | "{" globList "}"
    -- Alternative choose

globList ::=
  | glob
  | glob "," globList

atom ::=
  | id
  | range

id ::=
  | idCharFirst idChar

idCharFirst ::=
  | alphaNum

idChar ::=
  | idCharFirst
  | "_" | "-" | "."

range ::=
  | digit ".." digit
```

Examples:

- `+a/b` enables warnings prefixed with `a/b`, e.g., `a/b`, `a/b/c`, but not `a/bc` or `a`.
- `+a/*` enables warnings prefixed with `a/`, e.g., `a/b`, `a/b/c`, but not `a/bc` or `a`.
- `-*,+a` disables all the warnings but ones prefixed with `a`.
- `a/{+b,-c}` is equivalent to `+a/b,-a/c`
- `+a/{b,c}` is equivalent to `a/{+b,+c}` so as to `+a/b,+a/c`.
- `+{1..3,a}` is equivalent to `+1,+2,+3,+a`

## Exit codes

- `0` if no errors are detected.
- `1` if errors are detected.
