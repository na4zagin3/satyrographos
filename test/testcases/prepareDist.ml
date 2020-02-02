open Shexp_process
open Shexp_process.Infix

let fontsJunicode = "fonts/Junicode.ttf", "@@Junicode.ttf@@"

let hashFonts = "hash/fonts.satysfi-hash",
{|{"Junicode"  : <Single: {"src": "dist/fonts/Junicode.ttf"}>}|}

let packagesList = "packages/List.satyg",
{|@stage: persistent
module List = struct end|}

let unidataUnicodeData = "unidata/UnicodeData.txt",
{|0000;<control>;Cc;0;BN;;;;;N;NULL;;;;
0001;<control>;Cc;0;BN;;;;;N;START OF HEADING;;;;
0002;<control>;Cc;0;BN;;;;;N;START OF TEXT;;;;|}

let files = [ fontsJunicode; hashFonts; unidataUnicodeData; packagesList; ]

let empty dir =
  mkdir dir

let simple dir =
  List.iter files ~f:(fun (file, content) ->
    let path = FilePath.concat dir file in
    mkdir ~p:() (FilePath.dirname path)
    >> (stdout_to path (echo content))
  )

