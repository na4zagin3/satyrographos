open Core

let version = "0.0.3"

module Json = struct
  (*
  include Yojson.Safe
  type t = Json_derivers.Yojson.t
  let ( sexp_of_t, t_of_sexp, compare, hash ) = Json_derivers.Yojson.( sexp_of_t, t_of_sexp, compare, hash )
  *)
  include Yojson.Safe
  include Json_derivers.Yojson
  let to_yojson = ident
  let of_yojson x = Rresult.R.ok x
end

type opam_package = {
  name: string;
  version: string;
}
[@@deriving equal, sexp, yojson]

let x =
  opam_package_of_yojson
type opam_dependencies = {
  packages: opam_package list;
}
[@@deriving equal, sexp, yojson]

type dependencies =
  | Opam of opam_dependencies
[@@deriving equal, sexp, yojson]

type autogen = (string * Json.t) list
[@@deriving equal, sexp]

let autogen_to_yojson lvs =
  `Assoc lvs

let autogen_of_yojson (j : Yojson.Safe.t) =
  match j with
  | `Assoc lvs ->
    Rresult.R.ok lvs
  | _ ->
    Rresult.R.error "autogen_of_yojson: Invalid form"

type t = {
  satyrographos: string;
  dependencies: dependencies;
  autogen: autogen;
}
[@@deriving equal, sexp, yojson]


let make ~dependencies ~autogen = {
  satyrographos = version;
  dependencies;
  autogen;
}

let save_file_exn f ld =
  Out_channel.with_file f ~f:(fun oc ->
      let str =
        to_yojson ld
        |> YamlYojson.yaml_of_yojson
        |> Yaml.yaml_to_string
      in
      str
      |> Rresult.R.error_msg_to_invalid_arg
      |> Out_channel.output_string oc
    )

let load_file_exn f =
  In_channel.read_all f
  |> Yaml.yaml_of_string
  |> Rresult.R.error_msg_to_invalid_arg
  |> YamlYojson.yojson_of_yaml
  |> of_yojson
  |> Result.ok_or_failwith
