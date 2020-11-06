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

type persistent = {
  time: string;
  zone: string;
}
[@@deriving equal, yojson]

let module_struct data =
  [`Let (datetime_field_name,
         data.time
         |> Satysfi.value_of_string);
   `Let (tzname_field_name,
         data.zone
         |> Satysfi.value_of_string);
  ]

let generate_persistent () =
  (* TODO (gh-98) get the values from the lockfile *)
  let time = Time.now () in
  let zone =
    Time.Zone.local
    |> Lazy.force
  in
  { time =
      time
      |> Time.to_string_iso8601_basic ~zone;
    zone =
      zone
      |> Time.Zone.name;
  }

let generate_persistent_opt () =
  generate_persistent ()
  |> persistent_to_yojson
  |> Option.some

let generate ~outf ~persistent_yojson =
  let data =
    let persistent =
      Option.map ~f:persistent_of_yojson persistent_yojson
    in
    let module Rresult = Ppx_deriving_yojson_runtime.Result in
    match persistent with
    | Some (Rresult.Ok p) ->
      Format.fprintf  outf"autogen:%s: Using lockdowned values@." name;
      p
    | Some (Rresult.Error _) ->
      Format.fprintf outf "autogen:%s: Lockdown file is broken@." name;
      generate_persistent ()
    | None ->
      generate_persistent ()
  in

  let f = `Module ("Fonts", module_sig, module_struct data) in
  let decls =
    Satysfi.expr_experimental_message package_name
    @ [f] in
  let cont = Satysfi.format_file_to_string [] decls in
  Library.{ empty with
    name = Some name;
    version = Some "0.1";
    files = LibraryFiles.singleton package_path (`Content cont);
  }
