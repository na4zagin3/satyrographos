#!/bin/sh

test_satysfi_pkgs () {
    command satysfi --version >/dev/null 2>&1 || return $?

    PKGS="$(mktemp)"
    trap 'rm -- "$PKGS"' EXIT

    SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos library-opam list 2>/dev/null >"$PKGS"
    [[ 0 -eq "$( printf "%s\n" "$@" | sort - <"$PKGS" <"$PKGS" | uniq -u | wc -l)" ]]
}

test_omake () {
    command omake --version >/dev/null 2>&1
}

test_fontconfig () {
    command fc-scan --version >/dev/null 2>&1
}
