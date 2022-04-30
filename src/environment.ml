open Core

module OpamSwitch = struct
  include OpamSwitch

  let sexp_of_t v =
    OpamSwitch.to_string v
    |> [%sexp_of: string]

  let t_of_sexp sexp =
    [%of_sexp: string] sexp
    |> OpamSwitch.of_string
end

type t = {
  opam_switch: OpamSwitch.t option;
  opam_reg: OpamSatysfiRegistry.t option;
  dist_library_dir: string option;
}
[@@deriving sexp]


let empty = {
  opam_switch=None;
  opam_reg=None;
  dist_library_dir=None;
}

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

