open Core

module Location = Satyrographos.Location

type location =
  | SatyristesModLoc of (string * string * (int * int) option)
  | FileLoc of Location.t
  | OpamLoc of string

type hint =
  | MissingDependency of string

type diagnosis =
  (location list * [`Error | `Warning] * string)

let show_location ~outf ~basedir =
  let concat_with_basedir = FilePath.make_absolute basedir in
  function
  | SatyristesModLoc (buildscript_path, module_name, None) ->
    Format.fprintf outf "%s: (module %s):@." (concat_with_basedir buildscript_path) module_name
  | SatyristesModLoc (buildscript_path, module_name, Some (line, col)) ->
    Format.fprintf outf "%s:%d:%d: (module %s):@." (concat_with_basedir buildscript_path) line col module_name
  | FileLoc loc ->
    Format.fprintf outf "%s:@." (Location.display loc)
  | OpamLoc (opam_path) ->
    Format.fprintf outf "%s:@." (concat_with_basedir opam_path)

let show_locations ~outf ~basedir locs =
  List.rev locs
  |> List.iter ~f:(show_location ~outf ~basedir)

let show_problem ~outf ~basedir (locs, level, msg) =
  show_locations ~outf ~basedir locs;
  match level with
  | `Error->
    Format.fprintf outf "@[<2>Error:@ %s@]@.@." msg
  | `Warning ->
    Format.fprintf outf "@[<2>Warning:@ %s@]@.@." msg

let show_problems ~outf ~basedir =
  List.iter ~f:(show_problem ~outf ~basedir)

let get_opam_name ~opam ~opam_path =
  OpamFile.OPAM.name_opt opam
  |> Option.map ~f:OpamPackage.Name.to_string
  |> Option.value ~default:(FilePath.basename opam_path |> FilePath.chop_extension)
