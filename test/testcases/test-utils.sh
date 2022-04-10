#!/bin/sh

test_satysfi_pkgs () {
    PKGS=$(SATYROGRAPHOS_EXPERIMENTAL=1 satyrographos library-opam list 2>/dev/null )
    command satysfi --version >/dev/null 2>&1 && [[ 0 -eq "$( sort <(printf "%s\n" "$@") <(echo "$PKGS") <(echo "$PKGS") | uniq -u | wc -l)" ]]
}

test_omake () {
    command omake --version >/dev/null 2>&1
}

test_fontconfig () {
    command fc-scan --version >/dev/null 2>&1
}
