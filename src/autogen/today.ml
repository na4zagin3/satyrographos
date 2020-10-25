open Core
open Satyrographos

module Satysfi = Satyrographos_satysfi.Writer

module StringMap = Map.Make(String)

let name = "%today"

let package_name = "satyrographos/experimental/today"
let package_path = "packages/" ^ package_name ^ ".satyg"

let datetime_field_name = "datetime"
let tzname_field_name = "tzname"

let module_sig =
  [ `Val (datetime_field_name,
          `TConst "string");
    `Val (tzname_field_name,
          `TConst "string");
  ]

let module_struct time zone =
  [`Let (datetime_field_name,
         time
         |> Time.to_string_iso8601_basic ~zone
         |> Satysfi.value_of_string);
   `Let (tzname_field_name,
         zone
         |> Time.Zone.name
         |> Satysfi.value_of_string);
  ]

let generate ~outf:_ _library_map =
  (* TODO (gh-98) get the values from the lockfile *)
  let time = Time.now () in
  let zone =
    Time.Zone.local
    |> Lazy.force
  in

  let f = `Module ("Fonts", module_sig, module_struct time zone) in
  let decls =
    Satysfi.expr_experimental_message package_name
    @ [f] in
  let cont = Satysfi.format_file_to_string [] decls in
  Library.{ empty with
    name = Some name;
    version = Some "0.1";
    files = LibraryFiles.singleton package_path (`Content cont);
  }
