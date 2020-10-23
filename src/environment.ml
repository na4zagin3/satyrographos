type depot = {
  repo: Repository.t;
  reg: Registry.t;
}

type t = {
  depot: depot option;
  opam_reg: OpamSatysfiRegistry.t option;
  dist_library_dir: string option;
}

let empty = {
  depot=None;
  opam_reg=None;
  dist_library_dir=None;
}

open Core

type project_env = {
  buildscript_path: string;
  satysfi_runtime_dir: string;
}
[@@deriving sexp]

module P = Shexp_process

let get_satysfi_runtime_dir pe =
  pe.satysfi_runtime_dir

let get_satysfi_dist_dir pe =
  FilePath.concat (get_satysfi_runtime_dir pe) "dist"

let project_env_name = "SATYROGRAPHOS_PROJECT"
let set_project_env_cmd pe c =
  let serialized =
    [%sexp_of: project_env] pe
    |> Sexp.to_string_mach
  in
  P.set_env project_env_name serialized c

let get_project_env_cmd =
  let open P.Infix in
  P.get_env project_env_name
  >>| Option.map ~f:(fun str -> Sexp.of_string_conv_exn str [%of_sexp: project_env])

let get_project_env () =
  Sys.getenv project_env_name
  |> Option.map ~f:(fun str -> Sexp.of_string_conv_exn str [%of_sexp: project_env])

