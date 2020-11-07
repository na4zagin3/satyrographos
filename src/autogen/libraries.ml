open Core
open Satyrographos

module Satysfi = Satyrographos_satysfi.Writer

module StringMap = Map.Make(String)

let name = "$libraries"

let library_type_name = "library"
let library_name_field_name = "name"
let library_version_field_name = "version"
let library_list_field_name = "list"

let font_type_decl =
  [ `Type (
      (library_type_name, []),
      `TAlias (`TRecord [
        library_name_field_name, `TConst "string";
        library_version_field_name, `TConst "string";
      ]));
  ]

let library_module_sig =
  [ `Val (library_list_field_name,
      `TApp ([`TConst library_type_name], `TConst "list"));
  ]

let library_list_entry (name, (lib: Library.t)) =
  `Record
    [ "name", `LiteralString name;
      "version", `LiteralString (Option.value ~default:"" lib.version);
    ]

let package_name = "$libraries"
let package_path = "packages/" ^ package_name ^ ".satyg"

let generate ~outf:_ ~persistent_yojson:_ library_map =
  let records =
    Map.to_alist library_map
    |> List.map ~f:library_list_entry in
  let f = `Module ("Libraries", library_module_sig, [`Let ("list", `Array records)]) in
  let decls =
    Satysfi.expr_experimental_message package_name
    @ font_type_decl
    @ [f] in
  let cont = Satysfi.format_file_to_string [] decls in
  Library.{ empty with
    name = Some name;
    version = Some "0.1";
    files = LibraryFiles.singleton package_path (`Content cont);
  }
