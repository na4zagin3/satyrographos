#!/bin/sh

test_satysfi_pkgs () {
    command satysfi --version >/dev/null 2>&1 || return $?
    PKGS="$(mktemp)"
    SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos library-opam list 2>/dev/null >"$PKGS"
    [[ 0 -eq "$( printf "%s\n" "$@" | sort - <"$PKGS" <"$PKGS" | uniq -u | wc -l)" ]]

    trap 'rm "$PKGS"' 0
}

test_omake () {
    command omake --version >/dev/null 2>&1
}

test_fontconfig () {
    command fc-scan --version >/dev/null 2>&1
}
