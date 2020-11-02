open Core

include Lint_problem

module Location = Satyrographos.Location

type location =
  | SatyristesModLoc of (string * string * (int * int) option)
  | FileLoc of Location.t
  | OpamLoc of string

type level =
  [`Error | `Warning]
[@@deriving equal]

type diagnosis =
  { locs : location list;
    level : level;
    problem : problem;
  }


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

let show_problem ~outf ~basedir {locs; level; problem;} =
  show_locations ~outf ~basedir locs;
  Format.fprintf outf "@[<2>";
  begin match level with
  | `Error->
    Format.fprintf outf "Error: "
  | `Warning ->
    Format.fprintf outf "Warning: "
  end;
  Format.fprintf outf "%s@\n" (problem_class problem);
  show_problem ~outf problem;
  Format.fprintf outf "@]@.@."

let show_problems ~outf ~basedir =
  List.iter ~f:(show_problem ~outf ~basedir)

let get_opam_name ~opam ~opam_path =
  OpamFile.OPAM.name_opt opam
  |> Option.map ~f:OpamPackage.Name.to_string
  |> Option.value ~default:(FilePath.basename opam_path |> FilePath.chop_extension)
